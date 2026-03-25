package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ReelsDetails(
    val id: String?,
    val reels: List<Reel>?,
    val styling: ReelStyling?
) : CampaignDetails()

@Serializable
data class Reel(
    val id: String?,
    @SerialName("button_text") val buttonText: String?,
    val order: Int?,
    @SerialName("description_text") val descriptionText: String?,
    val video: String?,
    val likes: Int?,
    val thumbnail: String?,
    val link: String?
)

@Serializable
data class ReelStyling(
    val ctaBoxColor: String?,
    val cornerRadius: String?,
    val ctaTextColor: String?,
    val thumbnailWidth: String?,
    val likeButtonColor: String?,
    val thumbnailHeight: String?,
    val descriptionTextColor: String?
)

@Serializable
data class TooltipsDetails(
    @SerialName("_id") val id: String?,
    val campaign: String?,
    val name: String?,
    val tooltips: List<Tooltip>?,
    @SerialName("created_at") val createdAt: String?
) : CampaignDetails()

@Serializable
data class Tooltip(
    val type: String?,
    val url: String?,
    val link: String?,
    val enableBackdrop: Boolean?,
    val target: String?,
    val order: Int?,
    @SerialName("_id") val id: String?,
    val titleText: String?,
    val subtitleText: String?,
    val ctaText: String?,
    val styling: TooltipStyling?
)

@Serializable
data class TooltipStyling(
    val appearance: TooltipAppearance?,
    val cta: TooltipCta?,
    val subTitle: TooltipText?,
    val title: TooltipText?
)

@Serializable
data class TooltipCta(
    val borderRadius: TooltipCornerRadius? = null,
    val cornerRadius: TooltipCornerRadius? = null,
    val container: TooltipCtaContainer? = null,
    val margin: TooltipCtaMargin? = null,
    val text: TooltipCtaText? = null
)

@Serializable
data class TooltipCtaContainer(
    val alignment: String? = null,
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    @Serializable(with = NullableIntSerializer::class)
    val borderWidth: Int? = null,
    val ctaFullWidth: Boolean? = null,
    @Serializable(with = NullableIntSerializer::class)
    val ctaWidth: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val height: Int? = null
)

@Serializable
data class TooltipCtaMargin(
    val bottom: Int? = null,
    val left: Int? = null,
    val right: Int? = null,
    val top: Int? = null
)

@Serializable
data class TooltipCtaText(
    val color: String? = null,
    val fontSize: Int? = null,
    val fontFamily: String? = null,
    val fontDecoration: List<String>? = null
)

@Serializable
data class TooltipText(
    val color: String?,
    val fontSize: Int?,
    val textAlign: String?,
    val margin: TooltipMargin?,
    val fontFamily: String?,
    val fontDecoration: List<String>?
)

@Serializable
data class TooltipAppearance(
    val arrowStyle: TooltipArrow?,
    val backdropOpacity: Int?,
    val colors: TooltipColors?,
    val cornerRadius: TooltipCornerRadius?,
    val highlight: TooltipHighlight?,
    val imageDimensions: TooltipImageDimensions?,
    val padding: TooltipMargin?
)

@Serializable
data class TooltipArrow(
    val height: Int?,
    val width: Int?
)

@Serializable
data class TooltipColors(
    val arrow: String?,
    val backdrop: String?,
    val tooltip: String?
)

@Serializable
data class TooltipHighlight(
    val padding: Int?,
    val radius: Int?
)

@Serializable
data class TooltipImageDimensions(
    val height: Int?,
    val width: Int?
)

@Serializable
data class TooltipMargin(
    val top: Int?,
    val bottom: Int?,
    val left: Int?,
    val right: Int?
)

@Serializable
data class TooltipCornerRadius(
    val bottomLeft: Int?,
    val bottomRight: Int?,
    val topLeft: Int?,
    val topRight: Int?
)

