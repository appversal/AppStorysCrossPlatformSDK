package com.appversal.appstorys.core.model

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class SurveySlide(
    val id: String?,
    val order: Int?,
    val parent: String?,
    val title: String?,
    val subtitle: String?,
    val question: String?,
    val options: Map<String, String>?,
    val image: String?,
    val submitButtonText: String?,
    val logic: List<SurveyLogic>? = null,
    val additionalComment: AdditionalComment?,
    val createdAt: String? = null,
    val updatedAt: String? = null,
    val surveyQuestion: String? = null,
    val surveyOptions: Map<String, String>? = null,
    val hasOthers: Boolean? = null
)

@Serializable
data class SurveyLogic(
    val redirectTo: String?,
    val selectOption: List<String>? = null
)

@Serializable
data class AdditionalComment(
    val enabled: Boolean?,
    val placeholder: String?
)

@Serializable
data class SurveyDetails(
    val id: String?,
    val name: String?,
    val styling: SurveyStyling?,
    val surveyQuestion: String?,
    val surveyOptions: Map<String, String>?,
    val hasOthers: Boolean?,
    val campaign: String?,
    val slides: List<SurveySlide>? = null,
    val totalSlides: Int? = null,
    val thankYouTitle: String? = null,
    val thankYouText: String? = null,
    val thankYouImage: String? = null,
    val thankYouButtonText: String? = null,
    val thankYouButtonConfig: SurveyThankYouButtonConfig? = null
) : CampaignDetails()

@Serializable
data class SurveyThankYouButtonConfig(
    val action: String? = null,
    val enabled: Boolean? = null,
    val redirectUrl: String? = null
)

@Serializable
data class SurveyCtaContainer(
    val alignment: String? = null,
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val borderWidth: Int? = null,
    val ctaFullWidth: Boolean? = null,
    val ctaWidth: Int? = null,
    val height: Int? = null
)

@Serializable
data class SurveyCtaText(
    val color: String? = null,
    val fontDecoration: List<String>? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null
)

@Serializable
data class SurveyCtaConfig(
    val container: SurveyCtaContainer? = null,
    val cornerRadius: CornerRadius? = null,
    val margin: Margin? = null,
    val text: SurveyCtaText? = null
)

@Serializable
data class SurveyThankyouTextStyle(
    val color: String? = null,
    val fontDecoration: List<String>? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val margin: Margin? = null,
    val textAlign: String? = null
)

@Serializable
data class SurveyThankyouTextElement(
    val textStyle: SurveyThankyouTextStyle? = null
)

@Serializable
data class SurveyThankyouPage(
    val cta: SurveyCtaConfig? = null,
    val imageStyle: SurveyImageStyle? = null,
    val subtitle: SurveyThankyouTextElement? = null,
    val title: SurveyThankyouTextElement? = null
)

@Serializable
data class SurveyImageStyle(
    val height: Int? = null,
    val width: Int? = null,
    val margin: Margin? = null
)

@Serializable
data class SurveyAppearance(
    val backdropColor: String? = null,
    val backgroundColor: String? = null,
    val backdropOpacity: Int? = null,
    val backgroundOpacity: Int? = null,
    val cornerRadius: CornerRadius? = null,
    val displayDelay: Int? = null
)

@Serializable
data class SurveyOptionColors(
    val background: String? = null,
    val border: String? = null,
    val text: String? = null
)

@Serializable
data class SurveyOptionTextStyle(
    val borderwidth: JsonElement? = null,
    val fontDecoration: List<String>? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val textAlign: String? = null
)

@Serializable
data class SurveyOptionStyle(
    val colors: SurveyOptionColors? = null,
    val textStyle: SurveyOptionTextStyle? = null
)

@Serializable
data class SurveyAdditionalCommentsStyle(
    val colors: SurveyOptionColors? = null,
    val textStyle: SurveyOptionTextStyle? = null
)

@Serializable
data class SurveyOptionsConfig(
    val additionalComments: SurveyAdditionalCommentsStyle? = null,
    val bulletSpacing: String? = null,
    val nonSelectedOptions: SurveyOptionStyle? = null,
    val optionListStyle: String? = null,
    val optionsHeight: Int? = null,
    val optionsSpacing: String? = null,
    val selectedOptions: SurveyOptionStyle? = null,
    val cornerRadius: CornerRadius? = null
)

@Serializable
data class SurveyStyling(
    val optionColor: String?,
    val displayDelay: String?,
    val backgroundColor: String?,
    val optionTextColor: String?,
    val othersTextColor: String?,
    val surveyTextColor: String?,
    val ctaTextIconColor: String?,
    val ctaBackgroundColor: String?,
    val selectedOptionColor: String?,
    val surveyQuestionColor: String?,
    val othersBackgroundColor: String?,
    val selectedOptionTextColor: String?,
    val crossButton: SurveyCrossButton? = null,
    val thankyouPage: SurveyThankyouPage? = null,
    val appearance: SurveyAppearance? = null,
    val cta: SurveyCtaConfig? = null,
    val title: SurveyThankyouTextElement? = null,
    val subtitle: SurveyThankyouTextElement? = null,
    val options: SurveyOptionsConfig? = null
)

@Serializable
data class SurveyCrossButton(
    val color: BannerColors? = null,
    val enabled: Boolean? = null,
    val image: String? = null,
    val margin: BannerMargin? = null,
    val selectedStyle: String? = null,
    val size: Int? = null
)

