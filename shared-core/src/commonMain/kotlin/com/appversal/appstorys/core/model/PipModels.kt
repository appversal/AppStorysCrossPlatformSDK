package com.appversal.appstorys.core.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class PipDetails(
    val id: String?,
    val position: String?,
    val small_video: String?,
    val large_video: String?,
    val height: Int?,
    val width: Int?,
    val styling: PipStyling?,
    val link: String?,
    val campaign: String?,
    val button_text: String?,
    val crossButtonImage: String?,
    val muteImage: String?,
    val unmuteImage: String?,
    val maximiseImage: String?,
    val minimiseImage: String?,
) : CampaignDetails()

@Serializable
data class PipStyling(
    val ctaWidth: String?,
    val fontSize: String?,
    val ctaHeight: String?,
    val isMovable: Boolean?,
    val marginTop: String?,
    val fontFamily: String?,
    val marginLeft: String?,
    val marginRight: String?,
    val cornerRadius: String?,
    val ctaFullWidth: Boolean?,
    val marginBottom: String?,
    val fontDecoration: List<String>?,
    val ctaButtonTextColor: String?,
    val ctaButtonBackgroundColor: String?,
    val pipTopPadding: JsonElement?,
    val pipBottomPadding: JsonElement?,
    val expandablePip: String?,
    val videoSelection: String?,
    val soundToggle: SoundToggle?,
    val crossButton: BannerStyleConfig?,
    val expandControls: ExpandControls?,
    val cta: PipCta?,
    val appearance: PipAppearance?
)

@Serializable
data class PipAppearance(
    val defaultSound: String?,
    val pipHeight: String?,
    val pipWidth: String?
)

@Serializable
data class PipCta(
    val cornerRadius: CornerRadius? = null,
    val container: PipCtaContainer? = null,
    val margin: PipCtaMargin? = null,
    val text: PipCtaText? = null
)

@Serializable
data class PipCtaContainer(
    val alignment: String? = null,
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val borderWidth: JsonElement? = null,
    val ctaFullWidth: Boolean? = null,
    val ctaWidth: Int? = null,
    val height: JsonElement? = null
)

@Serializable
data class PipCtaMargin(
    val bottom: Int? = null,
    val left: Int? = null,
    val right: Int? = null,
    val top: Int? = null
)

@Serializable
data class PipCtaText(
    val color: String? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val fontWeight: String? = null,
    val fontStyle: String? = null,
    val textDecoration: List<String>? = null,
    val fontDecoration: List<String>? = null
)

@Serializable
data class SoundToggle(
    val defaultSound: String?,
    val enabled: Boolean?,
    val option: String?,
    val mute: MuteButtonConfig?,
    val unmute: UnmuteButtonConfig?
)

@Serializable
data class MuteButtonConfig(
    val colors: BannerColors?,
    val color: BannerColors?,
    val size: Int?,
    val margin: MuteUnmuteMargin?,
    val selectedStyle: String?,
    val image: String?
)

@Serializable
data class UnmuteButtonConfig(
    val colors: BannerColors?,
    val color: BannerColors?,
    val size: Int?,
    val margin: MuteUnmuteMargin?,
    val selectedStyle: String?,
    val image: String?
)

@Serializable
data class MuteUnmuteMargin(
    val top: Int? = null,
    val right: Int? = null,
    val bottom: Int? = null,
    val left: Int? = null
)

@Serializable
data class ExpandControls(
    val option: String?,
    val enabled: Boolean?,
    val maximise: MaximiseButtonStyleConfig?,
    val minimise: MinimiseButtonStyleConfig?
)

@Serializable
data class MaximiseButtonStyleConfig(
    val colors: BannerColors?,
    val color: BannerColors?,
    val size: Int?,
    val margin: MuteUnmuteMargin?,
    val selectedStyle: String?,
    val image: String?
)

@Serializable
data class MinimiseButtonStyleConfig(
    val colors: BannerColors?,
    val color: BannerColors?,
    val size: Int?,
    val margin: MuteUnmuteMargin?,
    val selectedStyle: String?,
    val image: String?
)

