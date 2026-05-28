package com.appversal.appstorys.core

import com.appversal.appstorys.core.api.ApiClient
import com.appversal.appstorys.core.api.ApiResult
import com.appversal.appstorys.core.api.KeyValueStore
import com.appversal.appstorys.core.api.SdkJson
import com.appversal.appstorys.core.engine.TriggerEventMatcher
import com.appversal.appstorys.core.engine.TriggerEventMatcher.TrackedEventData
import com.appversal.appstorys.core.model.Campaign
import com.appversal.appstorys.core.model.CampaignDeserializer
import com.appversal.appstorys.core.model.CampaignVariant
import com.appversal.appstorys.core.model.ReconcileUserRequest
import com.appversal.appstorys.core.model.TrackUserWebSocketRequest
import com.appversal.appstorys.core.model.TriggerEvent
import com.appversal.appstorys.core.model.UpdateUserPropertiesRequest
import com.appversal.appstorys.core.model.ValidateAccountRequest
import com.appversal.appstorys.core.platform.PlatformStorage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import com.appversal.appstorys.core.model.BannerDetails
import com.appversal.appstorys.core.model.BottomSheetDetails
import com.appversal.appstorys.core.model.CSATDetails
import com.appversal.appstorys.core.model.FloaterDetails
import com.appversal.appstorys.core.model.MilestoneDetails
import com.appversal.appstorys.core.model.ModalDetails
import com.appversal.appstorys.core.model.PipDetails
import com.appversal.appstorys.core.model.ReelsDetails
import com.appversal.appstorys.core.model.ScratchCardDetails
import com.appversal.appstorys.core.model.SpinTheWheelDetails
import com.appversal.appstorys.core.model.StoriesDetails
import com.appversal.appstorys.core.model.StoryGroup
import com.appversal.appstorys.core.model.SurveyDetails
import com.appversal.appstorys.core.model.TooltipsDetails
import com.appversal.appstorys.core.model.VariantCampaignDetails
import com.appversal.appstorys.core.model.WidgetDetails
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.serializer
import com.appversal.appstorys.core.utils.personalizeText
import com.appversal.appstorys.core.platform.getDeviceInfo
import kotlin.collections.emptyMap

class AppStorysCore(private val storage: PlatformStorage) {
    // ══════════════════════════════════════════════════════════════
    // INTERNAL STATE
    // Pure business state; no Android/Compose/UI references.
    // ══════════════════════════════════════════════════════════════
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val apiClient = ApiClient(storage = StorageAdapter(storage))

    private var appId = ""
    private var accountId = ""

    var accessToken: String = ""
        private set

    var currentScreen: String = ""
        private set

    var userId: String = ""
        private set

    var isAnonymousUser: Boolean = true
        private set

    private val _campaigns = MutableStateFlow<List<Campaign>>(emptyList())
    val campaigns: StateFlow<List<Campaign>> = _campaigns.asStateFlow()

    private val _disabledCampaigns = MutableStateFlow<List<String>>(emptyList())
    val disabledCampaigns: StateFlow<List<String>> = _disabledCampaigns.asStateFlow()

    private val _trackedEvents = MutableStateFlow<Set<TrackedEventData>>(emptySet())
    val trackedEvents: StateFlow<Set<TrackedEventData>> = _trackedEvents.asStateFlow()

    private val _campaignVariants = MutableStateFlow<List<CampaignVariant>>(emptyList())
    val campaignVariants: StateFlow<List<CampaignVariant>> = _campaignVariants.asStateFlow()

    private var personalizationData: Map<String, String>? = null

    // StateFlow so the Flutter plugin can combine it with campaigns — EventChannel
    // fires when isTestUser changes even if campaigns list stays empty (0-campaign screens).
    private val _isTestUser = MutableStateFlow(false)
    val isTestUserFlow: StateFlow<Boolean> = _isTestUser.asStateFlow()
    var isTestUser: Boolean
        get() = _isTestUser.value
        private set(value) { _isTestUser.value = value }

    enum class SdkState { Uninitialized, Initializing, Initialized, Paused, Error }

    var sdkState: SdkState = SdkState.Uninitialized
        private set

    private var campaignsJob: Job? = null

    private val systemEvents = setOf(
        "viewed", "clicked", "csat captured", "survey captured",
        "shared", "SurveySubmitted", "SurveyDismissed", "ThankYouCTAClicked"
    )
    private val _deviceInfo: Map<String, Any> by lazy {
        runCatching { getDeviceInfo() }.getOrElse {
            sdkLogError("DeviceInfo unavailable: ${it.message}")
            emptyMap()
        }.also { info ->
            if (info.isEmpty()) {
                sdkLogError("DeviceInfo: empty — device context unavailable")
            }
        }
    }
    // ══════════════════════════════════════════════════════════════
    // INITIALIZE
    // ══════════════════════════════════════════════════════════════
    fun initialize(appId: String, accountId: String, userId: String = "") {
        this.appId = appId
        this.accountId = accountId

        if (userId.isNotEmpty()) {
            this.userId = userId
            this.isAnonymousUser = false
            storage.putString("appstorys_user_id", userId)
            storage.putBoolean("appstorys_is_anonymous", false)
        } else {
            val saved = storage.getString("appstorys_user_id")
            if (!saved.isNullOrEmpty()) {
                this.userId = saved
                this.isAnonymousUser = storage.getBoolean("appstorys_is_anonymous", true)
            } else {
                this.userId = "${randomAnonymousSuffix()}_anonymous"
                this.isAnonymousUser = true
                storage.putString("appstorys_user_id", this.userId)
                storage.putBoolean("appstorys_is_anonymous", true)
            }
        }

        if (sdkState == SdkState.Initialized || sdkState == SdkState.Initializing) return

        sdkState = SdkState.Initializing

        scope.launch {
            try {
                val tokenResult = apiClient.validateAccount(
                    accountId = accountId,
                    request = ValidateAccountRequest(
                        app_id = appId,
                        account_id = accountId,
                        user_id = this@AppStorysCore.userId,
                        attributes = null
                    )
                )
                if (tokenResult is ApiResult.Success && !tokenResult.data.access_token.isNullOrBlank()) {
                    accessToken = tokenResult.data.access_token
                    sdkState = SdkState.Initialized
                    sdkLogDebug("Initialized. User: ${this@AppStorysCore.userId}")
                    _deviceInfo // force lazy evaluation so device info is captured at init time

                    if (currentScreen.isNotBlank() && campaignsJob?.isActive != true) {
                        getScreenCampaigns(currentScreen, emptyList())
                    }
                } else {
                    sdkLogError("Failed to get access token")
                    sdkState = SdkState.Error
                }
            } catch (e: Exception) {
                sdkLogError("Init error: ${e.message}")
                sdkState = SdkState.Error
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // VARIANT EXTRACTION
    // Resolves a campaign's VariantCampaignDetails into the concrete
    // typed details for the assigned variant. Called before emitting
    // campaigns so all platforms (Android, Flutter, RN) receive
    // already-resolved campaign objects.
    // ══════════════════════════════════════════════════════════════
    private fun extractVariantFromCampaign(campaign: Campaign, variantId: String): Campaign {
        return try {
            val details = campaign.details

            if (details !is VariantCampaignDetails) {
                sdkLogDebug("Campaign ${campaign.id} has no variants, returning as-is")
                return campaign
            }

            val variantData = details.variants[variantId]?.jsonObject
            if (variantData == null) {
                sdkLogError("Variant $variantId not found in campaign ${campaign.id}")
                return campaign
            }

            sdkLogDebug("Extracting variant $variantId from campaign ${campaign.id}")

            val variantDetails = when (campaign.campaignType) {
                "BAN"  -> SdkJson.decodeFromJsonElement(serializer<BannerDetails>(), variantData)
                "FLT"  -> SdkJson.decodeFromJsonElement(serializer<FloaterDetails>(), variantData)
                "CSAT" -> SdkJson.decodeFromJsonElement(serializer<CSATDetails>(), variantData)
                "WID"  -> SdkJson.decodeFromJsonElement(serializer<WidgetDetails>(), variantData)
                "REL"  -> SdkJson.decodeFromJsonElement(serializer<ReelsDetails>(), variantData)
                "TTP"  -> SdkJson.decodeFromJsonElement(serializer<TooltipsDetails>(), variantData)
                "PIP"  -> SdkJson.decodeFromJsonElement(serializer<PipDetails>(), variantData)
                "BTS"  -> SdkJson.decodeFromJsonElement(serializer<BottomSheetDetails>(), variantData)
                "SUR"  -> SdkJson.decodeFromJsonElement(serializer<SurveyDetails>(), variantData)
                "MOD"  -> SdkJson.decodeFromJsonElement(serializer<ModalDetails>(), variantData)
                "STR"  -> StoriesDetails(SdkJson.decodeFromJsonElement(serializer<List<StoryGroup>>(), variantData))
                "SCRT" -> SdkJson.decodeFromJsonElement(serializer<ScratchCardDetails>(), variantData)
                "MIL"  -> SdkJson.decodeFromJsonElement(serializer<MilestoneDetails>(), variantData)
                "STW"  -> SdkJson.decodeFromJsonElement(serializer<SpinTheWheelDetails>(), variantData)
                else -> {
                    sdkLogError("Campaign type ${campaign.campaignType} does not support variants")
                    null
                }
            }

            if (variantDetails != null) campaign.copy(details = variantDetails) else campaign

        } catch (e: Exception) {
            sdkLogError("Error extracting variant from campaign ${campaign.id}: ${e.message}")
            campaign
        }
    }

    // ══════════════════════════════════════════════════════════════
    // SCREEN CAMPAIGNS
    // Fetches eligible campaigns, merges missing cache entries, and updates
    // shared flows consumed by wrappers/bridges.
    // ══════════════════════════════════════════════════════════════
    fun getScreenCampaigns(screenName: String, positionList: List<String> = emptyList()) {
        campaignsJob?.cancel()
        campaignsJob = scope.launch {
            if (!waitForInit()) return@launch

            ensureActive()

            try {
                // Always clear dismissals + tracked events — every call is a fresh load.
                // Previously this only ran on screen-name change, which fails when the host
                // app integrates AppStorys on only some screens (currentScreen never updates
                // to the away-screen, so dismissals from the previous visit incorrectly
                // persist when the user returns).
                _campaigns.emit(emptyList())
                _disabledCampaigns.emit(emptyList())
                _trackedEvents.emit(emptySet())
                if (currentScreen != screenName) {
                    currentScreen = screenName
                    delay(100)
                }


                ensureActive()

                val eligibleResult = apiClient.getEligibleCampaigns(
                    accountId = accountId,
                    accessToken = accessToken,
                    request = TrackUserWebSocketRequest(
                        user_id = userId,
                        screenName = currentScreen
                    )
                )

                if (eligibleResult !is ApiResult.Success) {
                    sdkLogError("Failed to fetch eligible campaigns")
                    return@launch
                }

                val eligibleData = eligibleResult.data
                val eligibleCampaignIds = eligibleData.eligibleCampaignList ?: emptyList()

                val campaignsJsonResult = apiClient.fetchCampaignsJson(accountId = accountId)
                if (campaignsJsonResult !is ApiResult.Success) {
                    sdkLogError("Failed to fetch campaigns.json")
                    return@launch
                }

                var allCampaigns = campaignsJsonResult.data
                val cachedIds = allCampaigns.mapNotNull { it.id }.toSet()
                val missingIds = eligibleCampaignIds.filter { it !in cachedIds }

                if (missingIds.isNotEmpty()) {
                    val missingResult = apiClient.loadMissingCampaigns(
                        accessToken = accessToken,
                        campaignIds = missingIds
                    )
                    if (missingResult is ApiResult.Success) {
                        allCampaigns = allCampaigns + missingResult.data
                    }
                }

//                val campaignsList = allCampaigns.filter { campaign ->
//                    campaign.id in eligibleCampaignIds && campaign.screen?.equals(currentScreen, ignoreCase = true) == true
//                }
//
//                isTestUser = eligibleData.test_user ?: false
//                personalizationData = eligibleData.personalization_data
//
//                ensureActive()
//
//                _campaigns.emit(campaignsList)
//                _campaignVariants.emit(eligibleData.variants ?: emptyList())

                // AFTER:
                val variants = eligibleData.variants ?: emptyList()

                val campaignsList = allCampaigns
                    .filter { campaign ->
                        campaign.id in eligibleCampaignIds &&
                                campaign.screen?.equals(currentScreen, ignoreCase = true) == true
                    }
                    .map { campaign ->
                        val variant = variants.find { it.id == campaign.id }
                        if (variant != null) extractVariantFromCampaign(campaign, variant.v_id)
                        else campaign
                    }

                isTestUser = (eligibleData.test_user ?: false) && (eligibleData.screen_capture_enabled ?: false)
                personalizationData = eligibleData.personalization_data

                sdkLogDebug("test_user from backend: ${eligibleData.test_user}, screen_capture_enabled: ${eligibleData.screen_capture_enabled} → isTestUser set to: $isTestUser")
                ensureActive()

                _campaigns.emit(campaignsList)
                _campaignVariants.emit(variants)  // kept for Android wrapper back-compat

                if (isTestUser && positionList.isNotEmpty()) {
                    apiClient.identifyPositions(
                        accessToken = accessToken,
                        positionList = positionList,
                        screenName = currentScreen
                    )
                }

                sdkLogDebug("Campaigns for '$screenName': ${_campaigns.value.size}")
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                sdkLogError("Error getting campaigns for $screenName: ${e.message}")
            }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // EVENT TRACKING
    // ══════════════════════════════════════════════════════════════
    fun trackEvent(campaignId: String? = null, event: String, metadata: Map<String, Any>? = null) {
        scope.launch {
            if (accessToken.isEmpty()) return@launch

            if (event !in systemEvents) {
                _trackedEvents.update { it + TrackedEventData(event, metadata) }
            }

            try {
                val variantId = campaignId?.let { campId ->
                    _campaignVariants.value.find { it.id == campId }?.v_id
                }

                val mergedMetadata = if (event !in systemEvents) {
                    (metadata ?: emptyMap()) + _deviceInfo
                } else {
                    metadata ?: emptyMap()
                }

                val updatedMetadata = buildMap<String, Any> {
                    mergedMetadata.forEach { (key, value) -> put(key, value) }
                    if (variantId != null) put("variant_id", variantId)
                }

                apiClient.captureEvent(
                    accessToken = accessToken,
                    userId = userId,
                    campaignId = campaignId,
                    event = event,
                    metadata = updatedMetadata
                )
            } catch (e: Exception) {
                sdkLogError("Track event error: ${e.message}")
            }
        }
    }

    fun viaAppStorys(event: String) {
        scope.launch {
            _trackedEvents.update { it + TrackedEventData(eventName = event, metadata = null) }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // USER MANAGEMENT
    // ══════════════════════════════════════════════════════════════
    fun setUserId(newUserId: String) {
        if (newUserId.isEmpty()) {
            sdkLogError("Cannot set empty user ID")
            return
        }

        scope.launch {
            val previousUserId = userId
            val wasAnonymous = isAnonymousUser

            if (!wasAnonymous && previousUserId == newUserId) {
                sdkLogDebug("User ID already set to: $newUserId")
                return@launch
            }

            try {
                if (wasAnonymous) {
                    sdkLogDebug("Reconciling $previousUserId -> $newUserId")
                    apiClient.reconcileAnonymousUser(
                        accessToken = accessToken,
                        request = ReconcileUserRequest(
                            anonymous_user_id = previousUserId,
                            identified_user_id = newUserId
                        )
                    )
                }

                userId = newUserId
                isAnonymousUser = false
                storage.putString("appstorys_user_id", newUserId)
                storage.putBoolean("appstorys_is_anonymous", false)

                sdkLogDebug("User ID updated to: $newUserId")
            } catch (e: Exception) {
                sdkLogError("Error setting user ID: ${e.message}")
            }
        }
    }

    fun setUserProperties(attributes: Map<String, Any>) {
        scope.launch {
            if (userId.isBlank() || sdkState != SdkState.Initialized) {
                sdkLogError("Cannot set user properties: not initialized")
                return@launch
            }

            try {
                val enrichedAttributes = attributes + _deviceInfo
                apiClient.updateUserProperties(
                    accessToken = accessToken,
                    request = UpdateUserPropertiesRequest(
                        user_id = userId,
                        attributes = enrichedAttributes.toJsonElementMap()
                    )
                )
                sdkLogDebug("User properties updated: ${enrichedAttributes.keys}")
            } catch (e: Exception) {
                sdkLogError("Error updating user properties: ${e.message}")
            }
        }
    }

    fun captureCsatResponse(
        csatId: String,
        userId: String,
        rating: Double,
        feedbackOption: String?,
        additionalComments: String?
    ) {
        scope.launch {
            apiClient.sendCsatResponse(
                accessToken = accessToken,
                csatId = csatId,
                userId = userId,
                rating = rating,
                feedbackOption = feedbackOption,
                additionalComments = additionalComments
            )
        }
    }

    fun captureSurveyResponse(
        surveyId: String,
        userId: String,
        responseOptions: List<String>,
        comment: String?
    ) {
        scope.launch {
            apiClient.sendSurveyResponse(
                accessToken = accessToken,
                surveyId = surveyId,
                userId = userId,
                responseOptions = responseOptions,
                comment = comment
            )
        }
    }

    fun sendReelLikeStatus(campaignId: String, userId: String, isLiked: Boolean) {
        scope.launch {
            apiClient.sendReelLikeStatus(
                accessToken = accessToken,
                campaignId = campaignId,
                userId = userId,
                isLiked = isLiked
            )
        }
    }

    // ══════════════════════════════════════════════════════════════
    // CAMPAIGN FILTERING HELPERS
    // Used by Android composables and non-Android bridges.
    // ══════════════════════════════════════════════════════════════
    fun getFilteredCampaigns(campaignType: String, disabledIds: List<String> = _disabledCampaigns.value): List<Campaign> {
        return _campaigns.value.filter { campaign ->
            campaign.campaignType == campaignType &&
                campaign.id != null &&
                !disabledIds.contains(campaign.id) &&
                TriggerEventMatcher.shouldShowCampaign(
                    triggerEvent = campaign.triggerEvent,
                    campaignId = campaign.id,
                    trackedEvents = _trackedEvents.value
                )
        }
    }

    fun getFirstCampaignOfType(campaignType: String): Campaign? {
        return getFilteredCampaigns(campaignType).firstOrNull()
    }

    fun getWidgetCampaign(position: String?): Campaign? {
        return getFilteredCampaigns("WID").firstOrNull {
            if (position == null) it.position == null else it.position == position
        }
    }

    // Back-press campaigns are a special trigger mode that can include
    // additional event conditions besides the back-press sentinel.
    fun isBackPressCampaignReady(backPressCampaignConsumed: Boolean): Boolean {
        if (backPressCampaignConsumed) return false
        val disabled = _disabledCampaigns.value
        val currentEvents = _trackedEvents.value

        return _campaigns.value.any { campaign ->
            !disabled.contains(campaign.id) &&
                when (val trigger = campaign.triggerEvent) {
                    is TriggerEvent.ObjectTrigger -> {
                        val isBackPress = trigger.eventConfig.any { it.backPress == true }
                        if (!isBackPress) return@any false
                        val realConditions = trigger.eventConfig.filter { it.backPress == null }
                        if (realConditions.isEmpty()) true
                        else {
                            val matchingEvents = currentEvents.filter { it.eventName == trigger.event }
                            matchingEvents.any { tracked ->
                                TriggerEventMatcher.matchesAllConditions(realConditions, tracked.metadata)
                            }
                        }
                    }
                    else -> false
                }
        }
    }

    fun injectBackPressSentinel() {
        scope.launch {
            _trackedEvents.update { it + TrackedEventData(TriggerEventMatcher.BACK_PRESS_SENTINEL) }
        }
    }

    // Clears tracked entries for the trigger event once a dismissible campaign
    // is consumed, so it does not continuously re-qualify.
    // Prevents a campaign from repeatedly re-appearing just because old trigger events are still stored.
    fun clearTrackedEventForTrigger(triggerEvent: TriggerEvent?) {
        val eventName = when (triggerEvent) {
            is TriggerEvent.StringTrigger -> triggerEvent.event
            is TriggerEvent.ObjectTrigger -> triggerEvent.event
            else -> null
        } ?: return

        scope.launch {
            _trackedEvents.update { currentSet -> currentSet.filterNot { it.eventName == eventName }.toSet() }
        }
    }

    fun disableCampaign(campaignId: String) {
        scope.launch {
            _disabledCampaigns.update { it + campaignId }
        }
    }

    // ══════════════════════════════════════════════════════════════
    // LIFECYCLE
    // ══════════════════════════════════════════════════════════════
    fun onAppResumed() {
        if (sdkState == SdkState.Paused && currentScreen.isNotBlank()) {
            sdkState = SdkState.Initialized
            getScreenCampaigns(currentScreen, emptyList())
        }
    }

    fun onAppStopped() {
        sdkState = SdkState.Paused
        scope.launch {
            _campaigns.emit(emptyList())
            _trackedEvents.emit(emptySet())
        }
        campaignsJob?.cancel()
        campaignsJob = null
    }

    fun destroy() {
        scope.cancel()
    }

    // ══════════════════════════════════════════════════════════════
    // JSON BRIDGE METHODS
    // ══════════════════════════════════════════════════════════════
    fun getCampaignsJson(): String {
        val disabled = _disabledCampaigns.value
        return SdkJson.encodeToString(
            ListSerializer(CampaignDeserializer),
            _campaigns.value.filter { it.id == null || !disabled.contains(it.id) }
        )
    }

    fun getCampaignsByTypeJson(type: String): String {
        return SdkJson.encodeToString(
            ListSerializer(CampaignDeserializer),
            getFilteredCampaigns(type)
        )
    }

    fun getPersonalizationDataJson(): String {
        return SdkJson.encodeToString(
            MapSerializer(String.serializer(), String.serializer()),
            personalizationData ?: emptyMap()
        )
    }

    // Polls while initialization is in-flight so callers can safely await a
    // stable initialized/error state without depending on platform callbacks.
    private suspend fun waitForInit(): Boolean {
        var attempts = 0
        while (sdkState == SdkState.Initializing && attempts < 50) {
            delay(100)
            attempts++
        }
        return sdkState == SdkState.Initialized
    }

    fun personalizeText(text: String): String {
        return com.appversal.appstorys.core.utils.personalizeText(
            text,
            personalizationData ?: emptyMap()
        )
    }

    fun getDeviceMetadata(): Map<String, Any> = _deviceInfo

    suspend fun tooltipIdentify(
        screenName: String,
        childrenJson: String,
        screenshotBytes: ByteArray
    ) {
        if (accessToken.isEmpty() || userId.isEmpty()) return
        apiClient.tooltipIdentify(
            accessToken = accessToken,
            userId = userId,
            screenName = screenName,
            childrenJson = childrenJson,
            screenshotFileName = "tooltip_${System.currentTimeMillis()}.png",
            screenshotBytes = screenshotBytes
        )
    }

    // ══════════════════════════════════════════════════════════════
    // CROSS-PLATFORM BRIDGE HELPERS
    // Non-suspend wrappers and observation bridge for Swift/iOS.
    // ══════════════════════════════════════════════════════════════

    fun isInitialized(): Boolean = sdkState == SdkState.Initialized

    /** Non-suspend wrapper so Swift can call tooltipIdentify without coroutine machinery. */
    fun runTooltipIdentify(screenName: String, childrenJson: String, screenshotBytes: ByteArray) {
        scope.launch {
            runCatching {
                tooltipIdentify(screenName = screenName, childrenJson = childrenJson, screenshotBytes = screenshotBytes)
            }
        }
    }

    /**
     * Observes campaigns and isTestUser via a single callback, bridging StateFlow to Swift.
     * Payload format matches the Android EventChannel: {"c":[...],"s":true/false}
     * Returns a [CampaignObserver] whose [CampaignObserver.cancel] stops the flow collection.
     */
    fun observeCampaigns(onUpdate: (payload: String) -> Unit): CampaignObserver {
        val job = scope.launch {
            combine(campaigns, isTestUserFlow) { _, isTest ->
                val json = getCampaignsJson()
                "{\"c\":${json},\"s\":${isTest}}"
            }.collect { payload ->
                onUpdate(payload)
            }
        }
        return CampaignObserver(job)
    }

}

/** Cancellable handle returned by [AppStorysCore.observeCampaigns]. */
class CampaignObserver(private val job: Job) {
    fun cancel() = job.cancel()
}

// Thin adapter so ApiClient can reuse PlatformStorage through KeyValueStore.
private class StorageAdapter(private val storage: PlatformStorage) : KeyValueStore {
    override fun getString(key: String): String? = storage.getString(key)

    override fun putString(key: String, value: String) {
        storage.putString(key, value)
    }

    override fun getBoolean(key: String, default: Boolean): Boolean = storage.getBoolean(key, default)

    override fun putBoolean(key: String, value: Boolean) {
        storage.putBoolean(key, value)
    }
}

// Converts dynamic metadata into JSON-safe values for API payloads.
private fun Map<String, Any>.toJsonElementMap(): Map<String, JsonElement> {
    return mapValues { (_, value) ->
        when (value) {
            is String -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value)
            is Boolean -> JsonPrimitive(value)
            is Map<*, *> -> buildJsonObject {
                (value as Map<*, *>).forEach { (key, nestedValue) ->
                    if (key is String) {
                        put(key, nestedValue.toJsonElement())
                    }
                }
            }

            is List<*> -> buildJsonArray {
                value.forEach { item ->
                    add(item.toJsonElement())
                }
            }

            null -> JsonNull
            else -> JsonPrimitive(value.toString())
        }
    }
}

// Best-effort value conversion for nested metadata objects/lists.
private fun Any?.toJsonElement(): JsonElement {
    return when (this) {
        is String -> JsonPrimitive(this)
        is Number -> JsonPrimitive(this)
        is Boolean -> JsonPrimitive(this)
        null -> JsonNull
        else -> JsonPrimitive(this.toString())
    }
}

// Shared-core logger shim for debugging in all targets.
private fun sdkLogDebug(message: String) {
    println("AppStorysCore D: $message")
}

private fun sdkLogError(message: String) {
    println("AppStorysCore E: $message")
}

// Used for anonymous ID generation when no persisted user exists.
private fun randomAnonymousSuffix(): Long {
    return kotlin.random.Random.nextLong(1_000_000_000_000L, 9_999_999_999_999L)
}
