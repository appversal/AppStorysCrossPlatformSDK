package com.appversal.appstorys_flutter

import com.appversal.appstorys.core.AppStorysCore
import com.appversal.appstorys.core.platform.PlatformStorage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** AppstorysFlutterPlugin */
class AppstorysFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private val core: AppStorysCore by lazy { AppStorysCore(PlatformStorage()) }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "appstorys_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "getScreenCampaigns" -> handleGetScreenCampaigns(call, result)
            "getBannerJson" -> handleGetBannerJson(result)
            "getCampaignsJson" -> handleGetCampaignsJson(result)
            "getPersonalizationDataJson" -> handleGetPersonalizationDataJson(result)
            "setUserId" -> handleSetUserId(call, result)
            "setUserProperties" -> handleSetUserProperties(call, result)
            "trackEvent" -> handleTrackEvent(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId")
        val accountId = call.argument<String>("accountId")
        if (appId.isNullOrBlank()) {
            return missingArgument(result, "appId")
        }
        if (accountId.isNullOrBlank()) {
            return missingArgument(result, "accountId")
        }

        val userId = call.argument<String>("userId").orEmpty()
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

    private fun handleGetBannerJson(result: Result) {
        runBridgeCall(result) {
            core.getCampaignsByTypeJson("BAN")
        }
    }

    private fun handleGetCampaignsJson(result: Result) {
        runBridgeCall(result) {
            core.getCampaignsJson()
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

    private fun missingArgument(result: Result, name: String) {
        result.error("INVALID_ARGS", "Missing required argument: $name", null)
    }

    private fun runBridgeCall(result: Result, block: () -> Any?) {
        try {
            result.success(block())
        } catch (e: Exception) {
            result.error("APPSTORYS_ERROR", e.message ?: "Unexpected AppStorys error", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
