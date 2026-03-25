package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
data class VariantCampaignDetails(
    val variants: JsonObject
) : CampaignDetails()

@Serializable
data class ScratchCardDetails(
    val id: String?,
    val bannerImage: String?,
    val coverImage: String?,
    val height: Int?,
    val width: Int?,
    val soundFile: String?,
    val content: JsonObject? = null,
    val styling: JsonObject? = null,
    val button_text: String? = null,
    val link: String? = null,
    val coupon_code: String? = null
) : CampaignDetails()

@Serializable
data class MilestoneDetails(
    val id: String?,
    val content: MilestoneContent?,
    @SerialName("milestone_items") val milestoneItems: List<MilestoneItem>?,
    val styling: MilestoneStyling?
) : CampaignDetails()

@Serializable
data class MilestoneContent(
    val showStreaksAs: String?,
    val totalStepCount: Int?
)

@Serializable
data class MilestoneItem(
    val id: String?,
    val image: String?,
    val order: Int?,
    val triggerEvents: List<MilestoneTriggerEvent>?
)

@Serializable
data class MilestoneTriggerEvent(
    val eventName: String?
)

@Serializable
data class MilestoneStyling(
    val banner: MilestoneBannerStyling?
)

@Serializable
data class MilestoneBannerStyling(
    val marginTop: String?,
    val marginBottom: String?,
    val marginLeft: String?,
    val marginRight: String?,
    val borderRadiusTopLeft: String?,
    val borderRadiusTopRight: String?,
    val borderRadiusBottomLeft: String?,
    val borderRadiusBottomRight: String?
)

