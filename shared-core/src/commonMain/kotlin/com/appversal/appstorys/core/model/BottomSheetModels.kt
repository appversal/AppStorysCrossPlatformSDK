package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class BottomSheetDetails(
    @SerialName("_id") val id: String?,
    val campaign: String?,
    val name: String?,
    val type: String?,
    val bottomsheetType: String? = null,
    val created_at: String?,
    val backdropColor: String?,
    val backdropOpacity: JsonElement? = null,
    val backgroundColor: String?,
    val crossButton: BannerStyleConfig?,
    val elements: List<BottomSheetElement>?,
    val cornerRadius: CornerRadius? = null,
    val enableCrossButton: String?,
    val styling: BottomSheetStyling?,
    val triggerType: String?,
    val selectedEvent: String?,
) : CampaignDetails()

@Serializable
data class BottomSheetStyling(
    val crossButton: BannerStyleConfig?,
    val backgroundColor: String?,
)

@Serializable
data class BottomSheetCta(
    val container: BottomSheetCtaContainer?,
    val cornerRadius: CornerRadius?,
    val margin: BottomSheetCtaMargin?,
    val text: BottomSheetCtaText?
)

@Serializable
data class BottomSheetCtaContainer(
    val alignment: String?,
    val backgroundColor: String?,
    val borderColor: String?,
    val borderWidth: JsonElement? = null,
    val ctaBoxColor: String?,
    val ctaFullWidth: Boolean?,
    val ctaWidth: JsonElement? = null,
    val height: Int?
)

@Serializable
data class BottomSheetCtaMargin(
    val bottom: Int?,
    val left: Int?,
    val right: Int?,
    val top: Int?
)

@Serializable
data class BottomSheetCtaText(
    val color: String?,
    val fontDecoration: List<String>?,
    val fontFamily: String?,
    val fontSize: Int?
)

@Serializable
data class BottomSheetElement(
    val type: String?,
    val bottomsheetType: String?,
    val alignment: String?,
    val order: Int?,
    val id: String?,
    val url: String? = null,
    val imageLink: String? = null,
    val imageBackgroundColor: String? = null,
    val overlayButton: Boolean? = null,
    val cornerRadius: CornerRadius? = null,
    val titleText: String? = null,
    val titleFontStyle: FontStyle? = null,
    val titleFontSize: Int? = null,
    val descriptionText: String? = null,
    val descriptionFontStyle: FontStyle? = null,
    val descriptionFontSize: Int? = null,
    val titleLineHeight: Float? = null,
    val descriptionLineHeight: Float? = null,
    val spacingBetweenTitleDesc: Float? = null,
    val bodyBackgroundColor: String? = null,
    val ctaText: String? = null,
    val ctaLink: String? = null,
    val position: String? = null,
    val cta: BottomSheetCta? = null,
    val ctaBorderRadius: CornerRadius?,
    val ctaHeight: JsonElement? = null,
    val ctaWidth: JsonElement? = null,
    val ctaTextColour: String? = null,
    val ctaFontSize: String? = null,
    val ctaFontFamily: String? = null,
    val ctaFontDecoration: List<String>? = emptyList(),
    val ctaBoxColor: String? = null,
    val ctaBackgroundColor: String? = null,
    val ctaFullWidth: Boolean? = null,
    val paddingLeft: Int? = null,
    val paddingRight: Int? = null,
    val paddingTop: Int? = null,
    val paddingBottom: Int? = null,
    val marginLeft: Int? = null,
    val marginRight: Int? = null,
    val marginTop: Int? = null,
    val marginBottom: Int? = null
)

@Serializable
data class FontStyle(
    val fontFamily: String?,
    val fontSize: JsonElement? = null,
    val colour: String?,
    val decoration: List<String>?,
    val alignment: String?
)

