package com.appversal.appstorys_flutter

import com.appversal.appstorys.core.AppStorysCore
import com.appversal.appstorys.core.platform.PlatformStorage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/** AppstorysFlutterPlugin */
class AppstorysFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var campaignsEventChannel: EventChannel
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    // Single shared PlatformStorage instance for the plugin
    // Avoids relying on implicit SharedPreferences singleton behavior by
    // reusing the same storage instance when writing device info before
    // initializing the core and when constructing the core itself.
    // PlatformStorage is initialized when the plugin attaches so we can call
    // PlatformStorage.initialize(application) first and then create the instance.
    private lateinit var platformStorage: PlatformStorage

    private val core: AppStorysCore by lazy { AppStorysCore(platformStorage) }

    // Coroutine scope owned by the plugin — cancelled when the engine detaches.
    // CoroutineExceptionHandler logs errors instead of letting them propagate to
    // Android's default uncaught-exception handler (which kills the process).
    private val pluginScope = CoroutineScope(
        SupervisorJob() + Dispatchers.Default +
            CoroutineExceptionHandler { _, throwable ->
                android.util.Log.e("AppStorysPlugin", "Unhandled coroutine error", throwable)
            }
    )
    // Holds the active StateFlow collection job so it can be cancelled on stream cancel.
    private var campaignsCollectionJob: Job? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appstorys_flutter")
        channel.setMethodCallHandler(this)

        // Prefer explicit initialization of PlatformStorage with the Application
        // context to avoid reflection fallback inside PlatformStorage.
        PlatformStorage.initialize(flutterPluginBinding.applicationContext)

        // Now create the plugin's PlatformStorage instance. Creating it after
        // initialize() avoids any race where the storage tries to resolve an
        // application context before the host app had a chance to initialize it.
        platformStorage = PlatformStorage()

        // EventChannel pushes campaigns JSON to Dart whenever AppStorysCore._campaigns
        // StateFlow emits — this replaces all client-side polling in Dart widgets.
        campaignsEventChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            "appstorys_flutter/campaigns_stream"
        )
        campaignsEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                campaignsCollectionJob?.cancel()
                campaignsCollectionJob = pluginScope.launch {
                    // combine() fires whenever EITHER campaigns OR isTestUser changes.
                    // This is necessary because on screens with 0 campaigns, _campaigns
                    // stays at emptyList() so StateFlow deduplication prevents a re-emit
                    // after the API sets isTestUser. The isTestUserFlow provides the
                    // second trigger so the capture button updates correctly on all screens.
                    combine(core.campaigns, core.trackedEvents, core.isTestUserFlow) { campaigns, tracked, isTest ->
                        val json = core.getCampaignsJson()
                        android.util.Log.d("AppStorys", "[EventChannel] emitting — rawCampaigns: ${campaigns.size}, trackedEvents: ${tracked.map { it.eventName }}, filteredJson length: ${json.length}")
                        "{\"c\":${json},\"s\":${isTest}}"
                    }.collect { payload ->
                        withContext(Dispatchers.Main) {
                            sink.success(payload)
                        }
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                campaignsCollectionJob?.cancel()
                campaignsCollectionJob = null
            }
        })
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "getScreenCampaigns" -> handleGetScreenCampaigns(call, result)
            "getCampaignsJson" -> handleGetCampaignsJson(result)
            "getCampaignsByTypeJson" -> handleGetCampaignsByTypeJson(call, result)
            "getPersonalizationDataJson" -> handleGetPersonalizationDataJson(result)
            "setUserId" -> handleSetUserId(call, result)
            "getUserId" -> handleGetUserId(result)
            "isReady" -> handleIsReady(result)
            "setUserProperties" -> handleSetUserProperties(call, result)
            "trackEvent" -> handleTrackEvent(call, result)
            "dismissCampaign" -> handleDismissCampaign(call, result)
            "captureCsatResponse" -> handleCaptureCsatResponse(call, result)
            "captureSurveyResponse" -> handleCaptureSurveyResponse(call, result)
            "sendReelLikeStatus" -> handleSendReelLikeStatus(call, result)
            "personalizeText" -> handlePersonalizeText(call, result)
            "identifyElements" -> handleIdentifyElements(call, result)
            "viaAppStorys" -> handleViaAppStorys(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId") ?: return missingArgument(result, "appId")
        val accountId = call.argument<String>("accountId") ?: return missingArgument(result, "accountId")
        // null means userId was not passed from Dart — treat as explicit anonymous session.
        // Clearing the stored identified user here mirrors how device info is injected via
        // PlatformStorage before core.initialize() reads it.
        val rawUserId = call.argument<String>("userId")
        val userId = rawUserId ?: ""

        // Use the plugin's shared PlatformStorage instance so pre-init writes
        // and the core use the same storage object.
        val storage = platformStorage
        if (rawUserId == null) {
            // No userId passed → clear any previously stored identified user so the core
            // starts a fresh anonymous session instead of restoring the old test user.
            storage.putString("appstorys_user_id", "")
            storage.putBoolean("appstorys_is_anonymous", true)
        }
        val packageInfo = runCatching {
            flutterPluginBinding.applicationContext.packageManager
                .getPackageInfo(flutterPluginBinding.applicationContext.packageName, 0)
        }.getOrNull()
        storage.putString("app_version", packageInfo?.versionName ?: "")
        storage.putString("package_name", flutterPluginBinding.applicationContext.packageName)
        val metrics = flutterPluginBinding.applicationContext.resources.displayMetrics
        val configuration = flutterPluginBinding.applicationContext.resources.configuration
        storage.putString("screen_width", metrics.widthPixels.toString())
        storage.putString("screen_height", metrics.heightPixels.toString())
        storage.putString("screen_density", metrics.densityDpi.toString())
        storage.putString("orientation",
            if (configuration.orientation == android.content.res.Configuration.ORIENTATION_PORTRAIT)
                "portrait" else "landscape"
        )

        runBridgeCall(result) {
            core.initialize(appId = appId, accountId = accountId, userId = userId)
            null
        }
    }

    private fun handleGetScreenCampaigns(call: MethodCall, result: Result) {
        val screenName = call.argument<String>("screenName")
        if (screenName.isNullOrBlank()) {
            return missingArgument(result, "screenName")
        }

        val rawPositions = call.argument<List<Any?>>("positionList") ?: emptyList<Any?>()
        val positionList = rawPositions.mapNotNull { it as? String }

        runBridgeCall(result) {
            core.getScreenCampaigns(screenName = screenName, positionList = positionList)
            null
        }
    }

    private fun handleGetCampaignsJson(result: Result) {
        runBridgeCall(result) {
            core.getCampaignsJson()
        }
    }

    private fun handleGetCampaignsByTypeJson(call: MethodCall, result: Result) {
        val type = call.argument<String>("type").orEmpty()
        runBridgeCall(result) {
            core.getCampaignsByTypeJson(type)
        }
    }

    private fun handleGetPersonalizationDataJson(result: Result) {
        runBridgeCall(result) {
            core.getPersonalizationDataJson()
        }
    }

    private fun handleSetUserId(call: MethodCall, result: Result) {
        val userId = call.argument<String>("userId")
        if (userId.isNullOrBlank()) {
            return missingArgument(result, "userId")
        }

        runBridgeCall(result) {
            core.setUserId(newUserId = userId)
            null
        }
    }

    private fun handleGetUserId(result: Result) {
        runBridgeCall(result) { core.userId }
    }

    private fun handleIsReady(result: Result) {
        runBridgeCall(result) { core.sdkState == AppStorysCore.SdkState.Initialized }
    }

    private fun handleSetUserProperties(call: MethodCall, result: Result) {
        val attributes = call.argument<Map<String, Any?>>("attributes")
        if (attributes == null) {
            return missingArgument(result, "attributes")
        }

        val sanitizedAttributes = attributes.filterValues { it != null }.mapValues { it.value as Any }

        runBridgeCall(result) {
            core.setUserProperties(attributes = sanitizedAttributes)
            null
        }
    }

    private fun handleTrackEvent(call: MethodCall, result: Result) {
        val event = call.argument<String>("event")
        if (event.isNullOrBlank()) {
            return missingArgument(result, "event")
        }

        val campaignId = call.argument<String>("campaignId")
        val metadata =
            call.argument<Map<String, Any?>>("metadata")
                ?.filterValues { it != null }
                ?.mapValues { it.value as Any }

        runBridgeCall(result) {
            core.trackEvent(campaignId = campaignId, event = event, metadata = metadata)
            null
        }
    }

    private fun handleDismissCampaign(call: MethodCall, result: Result) {
        val campaignId = call.argument<String>("campaignId")
        if (campaignId.isNullOrBlank()) {
            return missingArgument(result, "campaignId")
        }

        runBridgeCall(result) {
            core.disableCampaign(campaignId)
            null
        }
    }

    private fun handleCaptureCsatResponse(call: MethodCall, result: Result) {
        val csatId = call.argument<String>("csatId").orEmpty()
        val userId = call.argument<String>("userId").orEmpty()
        val resolvedUserId = userId.ifBlank { core.userId }
        val rating = call.argument<Double>("rating") ?: 0.0
        val feedbackOption = call.argument<String>("feedbackOption")
        val additionalComments = call.argument<String>("additionalComments")

        runBridgeCall(result) {
            core.captureCsatResponse(csatId, resolvedUserId, rating, feedbackOption, additionalComments)
            null
        }
    }

    private fun handleCaptureSurveyResponse(call: MethodCall, result: Result) {
        val surveyId = call.argument<String>("surveyId").orEmpty()
        val userId = call.argument<String>("userId").orEmpty()
        val resolvedUserId = userId.ifBlank { core.userId }
        val responseOptions = call.argument<List<String>>("responseOptions") ?: emptyList()
        val comment = call.argument<String>("comment")

        runBridgeCall(result) {
            core.captureSurveyResponse(surveyId, resolvedUserId, responseOptions, comment)
            null
        }
    }

    private fun handleSendReelLikeStatus(call: MethodCall, result: Result) {
        val campaignId = call.argument<String>("campaignId").orEmpty()
        val userId = call.argument<String>("userId").orEmpty()
        val resolvedUserId = userId.ifBlank { core.userId }
        val isLiked = call.argument<Boolean>("isLiked") ?: false

        runBridgeCall(result) {
            core.sendReelLikeStatus(campaignId, resolvedUserId, isLiked)
            null
        }
    }

    private fun missingArgument(result: Result, name: String) {
        result.error("INVALID_ARGS", "Missing required argument: $name", null)
    }

    // Runs block() on a background IO thread so KMP runBlocking calls inside
    // shared-core never block the Android main thread (which would trigger an ANR).
    private fun runBridgeCall(result: Result, block: () -> Any?) {
        pluginScope.launch(Dispatchers.IO) {
            try {
                val value = block()
                withContext(Dispatchers.Main) { result.success(value) }
            } catch (t: Throwable) {
                android.util.Log.e("AppStorysPlugin", "Bridge call error", t)
                withContext(Dispatchers.Main) {
                    result.error("APPSTORYS_ERROR", t.message ?: "Unexpected AppStorys error", null)
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        campaignsCollectionJob?.cancel()
        pluginScope.cancel()
    }

    private fun handleViaAppStorys(call: MethodCall, result: Result) {
        val link = call.argument<String>("link").orEmpty()
        android.util.Log.d("AppStorys", "[viaAppStorys] bridge called — link: \"$link\", sentinel: \"viaAppStorys$link\"")
        runBridgeCall(result) {
            core.viaAppStorys("viaAppStorys$link")
            null
        }
    }

    private fun handlePersonalizeText(call: MethodCall, result: Result) {
        val text = call.argument<String>("text").orEmpty()
        runBridgeCall(result) { core.personalizeText(text) }
    }

    private fun handleIdentifyElements(call: MethodCall, result: Result) {
        val screenName = call.argument<String>("screenName") ?: return missingArgument(result, "screenName")
        val screenshot = call.argument<ByteArray>("screenshot") ?: return missingArgument(result, "screenshot")
        val children = call.argument<String>("children") ?: return missingArgument(result, "children")
        pluginScope.launch {
            runCatching {
                core.tooltipIdentify(
                    screenName = screenName,
                    childrenJson = children,
                    screenshotBytes = screenshot,
                )
            }
        }
        result.success(null)
    }

}
