package com.appversal.appstorys.core.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class ValidateAccountRequest(
    val app_id: String?,
    val account_id: String?,
    val user_id: String?,
    val attributes: Map<String, JsonElement>? = null
)

@Serializable
data class CampaignVariant(
    val id: String,
    val v_id: String
)

@Serializable
data class EligibleCampaignsResponse(
    val eligibleCampaignList: List<String>?,
    val userId: String,
    val variants: List<CampaignVariant>? = null,
    val personalization_data: Map<String, String>? = null,
    val test_user: Boolean? = null
)

@Serializable
data class ValidateAccountResponse(
    val access_token: String?
)

@Serializable
data class TrackUserWebSocketRequest(
    val user_id: String,
    val screenName: String? = null,
    val silentUpdate: Boolean? = null,
)

@Serializable(with = CampaignResponseDeserializer::class)
data class CampaignResponse(
    val userId: String?,
    val messageId: String?,
    val campaigns: List<Campaign>?
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Additional API Request/Response DTOs (Batch 1 continuation)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@Serializable
data class ReconcileUserRequest(
    val anonymous_user_id: String,
    val identified_user_id: String
)

@Serializable
data class IdentifyPositionsRequest(
    val screen_name: String?,
    val position_list: List<String>?
)

@Serializable
data class WebSocketConnectionResponse(
    val ws: WebSocketConfig,
    val userID: String,
    val screen_capture_enabled: Boolean?
)

@Serializable
data class WebSocketConfig(
    val expires: Int,
    val sessionID: String,
    val token: String,
    val url: String
)

@Serializable
data class UpdateUserPropertiesRequest(
    val user_id: String,
    val attributes: Map<String, JsonElement>
)

@Serializable
data class ReelStatusRequest(
    val user_id: String?,
    val action: String?,
    val reel: String?
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Feedback/Response DTOs (Survey, CSAT)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@Serializable
data class CsatFeedbackPostRequest(
    val csat: String?,
    val user_id: String?,
    val rating: Int?,
    val feedback_option: String? = null,
    val additional_comments: String = ""
)

@Serializable
data class SlideResponse(
    val slideId: String?,
    val responseOptions: List<String>?,
    val comment: String? = ""
)

@Serializable
data class SurveyFeedbackPostRequest(
    val user_id: String?,
    val survey: String?,
    val responseOptions: List<String>? = null,
    val comment: String? = "",
    val slideResponses: List<SlideResponse>? = null
)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Shared Styling & Helper Classes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@Serializable
data class TextStyling(
    val color: String?,
    val fontFamily: String?,
    val fontSize: Int?,
    val margin: CommonMargins? = null,
    val textAlign: String? = null,
    val fontDecoration: List<String>? = null
)

@Serializable
data class CommonMargins(
    val bottom: Int?,
    val left: Int?,
    val right: Int?,
    val top: Int?
)

@Serializable
data class Margin(
    val top: Int?,
    val bottom: Int?,
    val left: Int?,
    val right: Int?
)

@Serializable
data class Dimensions(
    val height: Int?,
    val width: Int?
)

