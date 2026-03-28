package com.appversal.appstorys.core.api

import com.appversal.appstorys.core.model.ValidateAccountRequest
import com.appversal.appstorys.core.model.ValidateAccountResponse
import com.appversal.appstorys.core.model.EligibleCampaignsResponse
import com.appversal.appstorys.core.model.TrackUserWebSocketRequest
import com.appversal.appstorys.core.model.Campaign
import com.appversal.appstorys.core.model.CampaignDeserializer
import com.appversal.appstorys.core.model.ReconcileUserRequest
import com.appversal.appstorys.core.model.IdentifyPositionsRequest
import com.appversal.appstorys.core.model.UpdateUserPropertiesRequest
import com.appversal.appstorys.core.model.CsatFeedbackPostRequest
import com.appversal.appstorys.core.model.ReelStatusRequest
import com.appversal.appstorys.core.platform.PlatformStorage
import com.appversal.appstorys.core.platform.logDebug as platformLogDebug
import com.appversal.appstorys.core.platform.logError as platformLogError
import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.logging.LogLevel
import io.ktor.client.plugins.logging.Logger
import io.ktor.client.plugins.logging.Logging
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.request.header
import io.ktor.client.request.get
import io.ktor.client.request.forms.MultiPartFormDataContent
import io.ktor.client.request.forms.formData
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.Headers
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.put

private const val TAG = "ApiClient"
private const val DEFAULT_USERS_BASE_URL = "https://users.appstorys.co/"
private const val DEFAULT_WEBSOCKET_BASE_URL = "https://users.appstorys.co/"  // WebSocket endpoint (same host, different protocol)
private const val DEFAULT_BACKEND_BASE_URL = "https://backend.appstorys.co/"
private const val DEFAULT_CDN_BASE_URL = "https://dev-cdn-campaign-appstorys.s3.ap-south-1.amazonaws.com"
private const val DEFAULT_TRACKING_BASE_URL = "https://tracking.appstorys.co/"
private const val PREF_CAMPAIGNS_JSON_PREFIX = "campaigns_json_"
private const val PREF_ETAG_PREFIX = "campaigns_etag_"

@OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
private val apiJson = Json {
    ignoreUnknownKeys = true
    isLenient = true
    coerceInputValues = true
    explicitNulls = false
}

class ApiClient(
    private val httpClient: HttpClient = createDefaultHttpClient(),
    private val usersBaseUrl: String = DEFAULT_USERS_BASE_URL,
    private val webSocketBaseUrl: String = DEFAULT_WEBSOCKET_BASE_URL,
    private val storage: KeyValueStore? = null,
    private val trackingBaseUrl: String = DEFAULT_TRACKING_BASE_URL,
    private val backendBaseUrl: String = DEFAULT_BACKEND_BASE_URL
) {
    // Lazy initialization to avoid calling PlatformStorage() at construction time
    private val storageDelegate: KeyValueStore by lazy {
        storage ?: PlatformKeyValueStore(PlatformStorage())
    }

    private fun getStorage(): KeyValueStore = storageDelegate

    suspend fun validateAccount(
        accountId: String,
        request: ValidateAccountRequest
    ): ApiResult<ValidateAccountResponse> = safeCall("validateAccount") {
        httpClient.post("$webSocketBaseUrl$accountId/validate-account") {
            contentType(ContentType.Application.Json)
            setBody(request)
        }
    }

    suspend fun getEligibleCampaigns(
        accountId: String,
        accessToken: String,
        request: TrackUserWebSocketRequest
    ): ApiResult<EligibleCampaignsResponse> = safeCall("getEligibleCampaigns") {
        httpClient.post("${webSocketBaseUrl}v2/$accountId/track-user-res") {
            contentType(ContentType.Application.Json)
            header("Authorization", bearerToken(accessToken))
            setBody(request)
        }
    }

    suspend fun fetchCampaignsJson(
        accountId: String,
        cdnBaseUrl: String = DEFAULT_CDN_BASE_URL
    ): ApiResult<List<Campaign>> {
        val etagKey = "$PREF_ETAG_PREFIX$accountId"
        val campaignsKey = "$PREF_CAMPAIGNS_JSON_PREFIX$accountId"
        val cachedEtag = getStorage().getString(etagKey)

        return try {
            val response = httpClient.get("$cdnBaseUrl/clients/$accountId/campaigns.json") {
                cachedEtag?.let { header(HttpHeaders.IfNoneMatch, it) }
            }

            when (response.status.value) {
                200 -> {
                    val payload = response.body<String>()
                    val campaigns = decodeCampaigns(payload)
                    getStorage().putString(campaignsKey, payload)
                    response.headers[HttpHeaders.ETag]?.let { getStorage().putString(etagKey, it) }
                    ApiResult.Success(campaigns)
                }

                304 -> {
                    val cachedPayload = getStorage().getString(campaignsKey)
                    if (cachedPayload.isNullOrBlank()) {
                        ApiResult.Error("CDN returned 304 but no cached campaigns found")
                    } else {
                        ApiResult.Success(decodeCampaigns(cachedPayload))
                    }
                }

                else -> fallbackToCachedCampaigns(
                    accountId = accountId,
                    campaignsKey = campaignsKey,
                    reason = "HTTP ${response.status.value}"
                )
            }
        } catch (e: Exception) {
            fallbackToCachedCampaigns(
                accountId = accountId,
                campaignsKey = campaignsKey,
                reason = e.message ?: "unknown error"
            )
        }
    }

    suspend fun loadMissingCampaigns(
        accessToken: String,
        campaignIds: List<String>
    ): ApiResult<List<Campaign>> {
        return try {
            val response = httpClient.post("${webSocketBaseUrl}load-campaign-data") {
                contentType(ContentType.Application.Json)
                header("Authorization", bearerToken(accessToken))
                setBody(campaignIds)
            }

            if (!response.status.isSuccess()) {
                val payload = response.body<String>()
                platformLogError(TAG, "loadMissingCampaigns failed: HTTP ${response.status.value} body=$payload")
                ApiResult.Error(
                    message = "Request failed with code ${response.status.value}",
                    code = response.status.value
                )
            } else {
                ApiResult.Success(decodeCampaigns(response.body<String>()))
            }
        } catch (e: Exception) {
            platformLogError(TAG, "loadMissingCampaigns failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun captureEvent(
        accessToken: String,
        userId: String,
        campaignId: String?,
        event: String,
        metadata: Map<String, Any> = emptyMap()
    ): ApiResult<Unit> {
        val requestBody = buildJsonObject {
            put("user_id", userId)
            campaignId?.let { put("campaign_id", it) }
            put("event", event)
            if (metadata.isNotEmpty()) {
                put("metadata", metadata.toJsonObject())
            }
        }

        return try {
            val response = httpClient.post("${trackingBaseUrl}capture-event") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(requestBody)
            }

            if (!response.status.isSuccess()) {
                val payload = response.body<String>()
                platformLogError(TAG, "captureEvent failed: HTTP ${response.status.value} body=$payload")
                ApiResult.Error(
                    message = "Request failed with code ${response.status.value}",
                    code = response.status.value
                )
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "captureEvent failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun identifyPositions(
        accessToken: String,
        positionList: List<String>,
        screenName: String
    ): ApiResult<Unit> {
        val request = IdentifyPositionsRequest(
            screen_name = screenName,
            position_list = positionList
        )
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v2/appinfo/identify-positions/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(request)
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "identifyPositions failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "identifyPositions failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun reconcileAnonymousUser(
        accessToken: String,
        request: ReconcileUserRequest
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}reconcile-anonymous-user") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(request)
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "reconcileAnonymousUser failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "reconcileAnonymousUser failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun updateUserProperties(
        accessToken: String,
        request: UpdateUserPropertiesRequest
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}update-user-atr") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(request)
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "updateUserProperties failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "updateUserProperties failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun sendCSATResponse(
        accessToken: String,
        request: CsatFeedbackPostRequest
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v1/campaigns/capture-csat-response/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(request)
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "sendCSATResponse failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "sendCSATResponse failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun sendCsatResponse(
        accessToken: String,
        csatId: String,
        userId: String,
        rating: Double,
        feedbackOption: String?,
        additionalComments: String?
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v1/campaigns/capture-csat-response/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(
                    buildJsonObject {
                        put("csat", csatId)
                        put("user_id", userId)
                        put("rating", rating)
                        feedbackOption?.let { put("feedback_option", it) }
                        additionalComments?.let { put("additional_comments", it) }
                    }
                )
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "sendCsatResponse failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "sendCsatResponse failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun sendSurveyResponse(
        accessToken: String,
        surveyId: String,
        userId: String,
        responseOptions: List<String>,
        comment: String?
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v1/campaigns/capture-survey-response/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(
                    buildJsonObject {
                        put("survey", surveyId)
                        put("user_id", userId)
                        put("responseOptions", JsonArray(responseOptions.map { JsonPrimitive(it) }))
                        comment?.let { put("comment", it) }
                    }
                )
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "sendSurveyResponse failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "sendSurveyResponse failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun sendReelLikeStatus(
        accessToken: String,
        request: ReelStatusRequest
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v1/campaigns/reel-like/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(request)
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "sendReelLikeStatus failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "sendReelLikeStatus failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun sendReelLikeStatus(
        accessToken: String,
        campaignId: String,
        userId: String,
        isLiked: Boolean
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${usersBaseUrl}api/v1/campaigns/reel-like/") {
                contentType(ContentType.Application.Json)
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(
                    buildJsonObject {
                        put("campaign_id", campaignId)
                        put("user_id", userId)
                        put("is_liked", isLiked)
                    }
                )
            }
            if (!response.status.isSuccess()) {
                platformLogError(TAG, "sendReelLikeStatus failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "sendReelLikeStatus failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    suspend fun tooltipIdentify(
        accessToken: String,
        userId: String,
        screenName: String,
        childrenJson: String,
        screenshotBytes: ByteArray,
        screenshotFileName: String = "screenshot.png",
        screenshotMimeType: String = "image/png"
    ): ApiResult<Unit> {
        return try {
            val response = httpClient.post("${backendBaseUrl}api/v1/appinfo/identify-elements/") {
                header(HttpHeaders.Authorization, bearerToken(accessToken))
                setBody(
                    MultiPartFormDataContent(
                        formData {
                            append("screenName", screenName)
                            append("user_id", userId)
                            append("children", childrenJson)
                            append(
                                "screenshot",
                                screenshotBytes,
                                Headers.build {
                                    append(HttpHeaders.ContentType, screenshotMimeType)
                                    append(HttpHeaders.ContentDisposition, "filename=\"$screenshotFileName\"")
                                }
                            )
                        }
                    )
                )
            }

            if (!response.status.isSuccess()) {
                platformLogError(TAG, "tooltipIdentify failed: HTTP ${response.status.value}")
                ApiResult.Error("Request failed with code ${response.status.value}", response.status.value)
            } else {
                ApiResult.Success(Unit)
            }
        } catch (e: Exception) {
            platformLogError(TAG, "tooltipIdentify failed: ${e.message}")
            ApiResult.Error(message = e.message ?: "Unexpected error")
        }
    }

    private fun decodeCampaigns(payload: String): List<Campaign> {
        val element = apiJson.decodeFromString<JsonElement>(payload)
        val array = element.jsonArray
        return array.map { campaignElement -> apiJson.decodeFromJsonElement(CampaignDeserializer, campaignElement) }
    }

    private fun fallbackToCachedCampaigns(
        accountId: String,
        campaignsKey: String,
        reason: String
    ): ApiResult<List<Campaign>> {
        val cachedPayload = getStorage().getString(campaignsKey)
        return if (cachedPayload.isNullOrBlank()) {
            platformLogError(TAG, "fetchCampaignsJson failed for account=$accountId and no cache available: $reason")
            ApiResult.Error("Unable to fetch campaigns: $reason")
        } else {
            platformLogDebug(TAG, "Using cached campaigns for account=$accountId after fetch failure: $reason")
            try {
                ApiResult.Success(decodeCampaigns(cachedPayload))
            } catch (e: Exception) {
                platformLogError(TAG, "Failed to parse cached campaigns for account=$accountId: ${e.message}")
                ApiResult.Error("Unable to parse cached campaigns")
            }
        }
    }
}

sealed class ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>()
    data class Error(val message: String, val code: Int? = null) : ApiResult<Nothing>()
}

interface KeyValueStore {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getBoolean(key: String, default: Boolean): Boolean
    fun putBoolean(key: String, value: Boolean)
}

private class PlatformKeyValueStore(
    private val platformStorage: PlatformStorage
) : KeyValueStore {
    override fun getString(key: String): String? = platformStorage.getString(key)

    override fun putString(key: String, value: String) {
        platformStorage.putString(key, value)
    }

    override fun getBoolean(key: String, default: Boolean): Boolean =
        platformStorage.getBoolean(key, default)

    override fun putBoolean(key: String, value: Boolean) {
        platformStorage.putBoolean(key, value)
    }
}

private fun createDefaultHttpClient(): HttpClient {
    return HttpClient {
        install(ContentNegotiation) {
            json(apiJson)
        }
        install(HttpTimeout) {
            requestTimeoutMillis = 30000
            connectTimeoutMillis = 30000
            socketTimeoutMillis = 30000
        }
        install(Logging) {
            level = LogLevel.INFO
            logger = object : Logger {
                override fun log(message: String) {
                    platformLogDebug(TAG, message)
                }
            }
        }
    }
}

private suspend inline fun <reified T> safeCall(
    operation: String,
    call: () -> HttpResponse
): ApiResult<T> {
    return try {
        val response = call()
        if (!response.status.isSuccess()) {
            val payload = response.body<String>()
            platformLogError(TAG, "$operation failed: HTTP ${response.status.value} body=$payload")
            ApiResult.Error(
                message = "Request failed with code ${response.status.value}",
                code = response.status.value
            )
        } else {
            ApiResult.Success(response.body())
        }
    } catch (e: Exception) {
        platformLogError(TAG, "$operation failed: ${e.message}")
        ApiResult.Error(message = e.message ?: "Unexpected error")
    }
}

private fun bearerToken(token: String): String {
    return if (token.startsWith("Bearer ", ignoreCase = true)) token else "Bearer $token"
}

private fun Map<String, Any>.toJsonObject(): JsonObject {
    return buildJsonObject {
        for ((key, value) in this@toJsonObject) {
            put(key, value.toJsonElement())
        }
    }
}

private fun Any?.toJsonElement(): JsonElement {
    return when (this) {
        null -> JsonNull
        is JsonElement -> this
        is String -> JsonPrimitive(this)
        is Number -> JsonPrimitive(this)
        is Boolean -> JsonPrimitive(this)
        is Map<*, *> -> {
            val map = this.entries
                .mapNotNull { (k, v) -> (k as? String)?.let { key -> key to v.toJsonElement() } }
                .toMap()
            JsonObject(map)
        }

        is List<*> -> JsonArray(this.map { it.toJsonElement() })
        else -> JsonPrimitive(this.toString())
    }
}

