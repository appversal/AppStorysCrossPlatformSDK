package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class CSATDetails(
    val id: String?,
    val title: String?,
    val height: Int?,
    val width: Int?,
    val styling: CSATStyling?,
    val thankyouImage: String?,
    val thankyouText: String?,
    val thankyouDescription: String?,
    val highStarText: String?,
    val lowStarText: String?,
    @SerialName("description_text") val descriptionText: String?,
    @SerialName("feedback_option") val feedbackOption: FeedbackOption?,
    val campaign: String?,
    val link: String?
) : CampaignDetails()

@Serializable
data class FeedbackOption(
    val option1: String?,
    val option2: String?,
    val option3: String?,
    val option4: String?,
    val option5: String?,
    val option6: String?,
    val option7: String?,
    val option8: String?,
    val option9: String?,
    val option10: String?,
) {
    fun toList(): List<String> = listOf(
        option1 ?: "",
        option2 ?: "",
        option3 ?: "",
        option4 ?: "",
        option5 ?: "",
        option6 ?: "",
        option7 ?: "",
        option8 ?: "",
        option9 ?: "",
        option10 ?: "",
    ).filter { it.isNotBlank() }
}

@Serializable
data class CSATStyling(
    val fontSize: Int? = null,
    val appearance: CsatAppearance?,
    val csatCrossButton: BannerStyleConfig? = null,
    @SerialName("crossButton")
    val crossButton: BannerStyleConfig? = null,
    val feedbackPage: CsatFeedbackPage?,
    val initialFeedback: CsatInitialFeedback?,
    val rating: CsatRating?,
    val thankyouPage: CsatThankyouPage?
)

@Serializable
data class CsatEmojiConfig(
    val selected: CsatEmojiState?,
    val unselected: CsatEmojiState?,
    val values: List<String>?
)

@Serializable
data class CsatEmojiState(
    val stylingContainer: CsatStylingContainer?
)

@Serializable
data class CsatStylingContainer(
    val border: String?,
    val borderWidth: Int?,
    val fill: String?
)

@Serializable
data class CsatNumberConfig(
    val high: CsatNumberState?,
    val low: CsatNumberState?,
    val unselected: CsatNumberState?,
    val stylingNumber: CsatNumberTextStyle?
)

@Serializable
data class CsatNumberState(
    val stylingContainer: CsatStylingContainer?,
    val stylingNumber: CsatNumberTextStyle?
)

@Serializable
data class CsatNumberTextStyle(
    val text: String?,
    val textSize: Int?
)

@Serializable
data class CsatAppearance(
    val backgroundColor: String?,
    val borderRadius: Int?,
    val displayDelay: JsonElement?,
    val margin: Margin?,
    val padding: Margin?
)

@Serializable
data class CsatFeedbackPage(
    val additionalComments: CsatAdditionalComments?,
    val options: CsatOptions?,
    val submitButton: CsatButton?
)

@Serializable
data class CsatAdditionalComments(
    val colors: CsatColors?,
    val enabled: Boolean?,
    val textStyle: CsatTextStyle?,
    val placeholder: String? = null
)

@Serializable
data class CsatOptions(
    val cornerRadius: CornerRadius? = null,
    val nonSelectedOptions: CsatOptionStyle?,
    val selectedOptions: CsatOptionStyle?,
    val optionsHeight: Int? = null,
    val optionsSpacing: Int? = null
)

@Serializable
data class CsatOptionStyle(
    val colors: CsatColors?,
    val textStyle: CsatTextStyle?
)

@Serializable
data class CsatButton(
    val colors: CsatColors? = null,
    val containerRadius: CornerRadius? = null,
    val containerStyle: CsatContainerStyle? = null,
    val fullWidth: Boolean? = null,
    val margin: Margin? = null,
    val padding: Margin? = null,
    val text: String? = null,
    val textStyle: CsatTextStyle? = null,
    val cta: CsatCtaConfig? = null,
    val enabled: Boolean? = null
)

@Serializable
data class CsatCtaConfig(
    val container: CsatCtaContainer?,
    val cornerRadius: CornerRadius?,
    val margin: Margin?,
    val text: CsatCtaText?
)

@Serializable
data class CsatCtaContainer(
    val alignment: String?,
    val backgroundColor: String?,
    val borderColor: String?,
    val borderWidth: Int?,
    val ctaFullWidth: Boolean?,
    val ctaWidth: Int?,
    val height: Int?
)

@Serializable
data class CsatCtaText(
    val color: String?,
    val fontDecoration: List<String>?,
    val fontFamily: String?,
    val fontSize: Int?
)

@Serializable
data class CsatContainerStyle(
    val alignment: String?,
    val borderWidth: Int?,
    val height: Int?,
    val width: Int?
)

@Serializable
data class CsatInitialFeedback(
    val subtitle: CsatTextElement?,
    val title: CsatTextElement?
)

@Serializable
data class CsatTextElement(
    val alignment: String? = null,
    val color: String? = null,
    val textAlign: String? = null,
    val textStyle: CsatTextStyle? = null
)

@Serializable
data class CsatRating(
    val displayText: String? = null,
    val high: CsatRatingStyle? = null,
    val low: CsatRatingStyle? = null,
    val unselected: CsatRatingStyle? = null,
    val alignment: String? = null,
    val ratingType: String? = null,
    val star: CsatStarConfig? = null,
    val emoji: CsatEmojiConfig? = null,
    val number: CsatNumberConfig? = null,
    val highRatingSubtitle: String? = null,
    val highRatingTitle: String? = null,
    val lowRatingSubtitle: String? = null,
    val lowRatingTitle: String? = null
)

@Serializable
data class CsatStarConfig(
    val high: CsatStarStyle?,
    val low: CsatStarStyle?,
    val unselected: CsatStarStyle?
)

@Serializable
data class CsatStarStyle(
    val stylingContainer: CsatStylingStar?,
    val stylingStar: CsatStylingStar?
)

@Serializable
data class CsatStylingStar(
    val background: String?,
    val border: String?,
    val borderWidth: Int?
)

@Serializable
data class CsatRatingStyle(
    val background: String?,
    val border: String?,
    val borderWidth: Int?,
    val highRatingTitle: String?,
    val lowRatingTitle: String?,
    val highRatingSubtitle: String?,
    val lowRatingSubtitle: String?
)

@Serializable
data class CsatThankyouPage(
    val doneButton: CsatButton?,
    val imageStyle: CsatImageStyle?,
    val subtitle: CsatTextElement?,
    val title: CsatTextElement?
)

@Serializable
data class CsatImageStyle(
    val width: Int?,
    val height: Int?,
    val margin: Margin?,
    val padding: Margin?
)

@Serializable
data class CsatColors(
    val background: String?,
    val border: String?,
    val text: String?
)

@Serializable
data class CsatTextStyle(
    val alignment: String? = null,
    val font: String? = null,
    val size: Int? = null,
    val color: String? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val textAlign: String? = null,
    val fontDecoration: List<String>? = null
)

