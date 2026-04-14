package com.appstorysreactnative

import com.appversal.appstorys.core.AppStorysCore
import com.appversal.appstorys.core.platform.PlatformStorage
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.bridge.ReadableMap

class AppStorysModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    private val core: AppStorysCore

    init {
        val storage = PlatformStorage()
        core = AppStorysCore(storage)
    }

    override fun getName() = "AppStorysReactNative"

    private fun invokeCoreMethodOrThrow(methodName: String, vararg args: Any?) {
        val method = core.javaClass.methods.firstOrNull {
            it.name == methodName && it.parameterTypes.size == args.size
        } ?: throw NoSuchMethodException("$methodName is not available in this AppStorysCore version")

        method.invoke(core, *args)
    }

    @ReactMethod
    fun initialize(appId: String, accountId: String, userId: String, promise: Promise) {
        try {
            val storage = PlatformStorage()
            val packageInfo = runCatching {
                reactApplicationContext.packageManager
                    .getPackageInfo(reactApplicationContext.packageName, 0)
            }.getOrNull()
            storage.putString("app_version", packageInfo?.versionName ?: "")
            storage.putString("package_name", reactApplicationContext.packageName)

            core.initialize(appId = appId, accountId = accountId, userId = userId)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    @ReactMethod
    fun getScreenCampaigns(screenName: String, promise: Promise) {
        try {
            core.getScreenCampaigns(screenName)
            promise.resolve(true)
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }

    @ReactMethod
    fun getCampaignsJson(promise: Promise) {
        try { promise.resolve(core.getCampaignsJson()) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun getCampaignsByTypeJson(type: String, promise: Promise) {
        try { promise.resolve(core.getCampaignsByTypeJson(type)) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun getPersonalizationDataJson(promise: Promise) {
        try { promise.resolve(core.getPersonalizationDataJson()) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun getUserId(promise: Promise) {
        promise.resolve(core.userId)
    }

    @ReactMethod
    fun isReady(promise: Promise) {
        promise.resolve(core.sdkState == AppStorysCore.SdkState.Initialized)
    }

    @ReactMethod
    fun trackEvent(campaignId: String?, event: String, metadata: ReadableMap?, promise: Promise) {
        try {
            val metaMap = metadata?.toHashMap()?.mapValues { it.value as Any }
            core.trackEvent(campaignId, event, metaMap)
            promise.resolve(true)
        } catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun setUserId(userId: String, promise: Promise) {
        try { core.setUserId(userId); promise.resolve(true) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun setUserProperties(attributes: ReadableMap, promise: Promise) {
        try {
            val map = attributes.toHashMap().mapValues { it.value as Any }
            core.setUserProperties(map)
            promise.resolve(true)
        } catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun dismissCampaign(campaignId: String, promise: Promise) {
        try { core.disableCampaign(campaignId); promise.resolve(true) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun captureCsatResponse(
        csatId: String, userId: String, rating: Double,
        feedbackOption: String?, additionalComments: String?, promise: Promise
    ) {
        try {
            invokeCoreMethodOrThrow(
                "captureCsatResponse",
                csatId,
                userId,
                rating,
                feedbackOption,
                additionalComments
            )
            promise.resolve(true)
        } catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun captureSurveyResponse(
        surveyId: String, userId: String, responseOptions: ReadableArray,
        comment: String?, promise: Promise
    ) {
        try {
            val options = (0 until responseOptions.size()).mapNotNull { responseOptions.getString(it) }
            invokeCoreMethodOrThrow("captureSurveyResponse", surveyId, userId, options, comment)
            promise.resolve(true)
        } catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun sendReelLikeStatus(
        campaignId: String, userId: String, isLiked: Boolean, promise: Promise
    ) {
        try { invokeCoreMethodOrThrow("sendReelLikeStatus", campaignId, userId, isLiked); promise.resolve(true) }
        catch (e: Exception) { promise.reject("ERROR", e.message) }
    }

    @ReactMethod
    fun personalizeText(text: String, promise: Promise) {
        try {
            promise.resolve(core.personalizeText(text))
        } catch (e: Exception) {
            promise.reject("ERROR", e.message)
        }
    }
}