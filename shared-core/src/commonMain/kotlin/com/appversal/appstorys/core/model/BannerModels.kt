package com.appversal.appstorys.core.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class BannerDetails(
    val id: String?,
    val image: String?,
    val width: Int?,
    val height: Int?,
    val link: JsonElement?,
    val styling: BannerStyling?,
    val lottie_data: String?,
    val crossButtonImage: String?
) : CampaignDetails()

@Serializable
data class BannerStyling(
    val enableCloseButton: Boolean?,
    val marginLeft: Int?,
    val marginRight: Int?,
    val marginBottom: Int?,
    val topLeftRadius: String?,
    val topRightRadius: String?,
    val bottomLeftRadius: String?,
    val bottomRightRadius: String?,
    val crossButton: BannerStyleConfig?,
)

@Serializable
data class BannerStyleConfig(
    val colors: BannerColors?,
    val color: BannerColors?,
    val size: Int?,
    val margin: BannerMargin?,
    val enabled: Boolean? = null,
    val image: String? = null,
    val option: String? = null,
    val selectedStyle: String? = null
)

@Serializable
data class BannerColors(
    val cross: String?,
    val fill: String?,
    val stroke: String?
)

@Serializable
data class BannerMargin(
    val top: Int?,
    val right: Int?,
    val bottom: Int?,
    val left: Int?
)

