package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SpinTheWheelDetails(
    val id: String? = null,
    // Direct fields from backend
    val popupTitle: String? = null,
    val popupDescription: String? = null,
    val spinButtonText: String? = null,
    val availableSpins: Int? = null,
    val enableBackdrop: Boolean? = null,
    val rewardDisplayMode: String? = null, // "pop-up" or other modes
    val slices: List<WheelSlice>? = null,
    val content: SpinWheelContent? = null,
    val styling: SpinWheelStyling? = null,
    val link: String? = null, // Redirect link for CTA button
    val button_text: String? = null // Alternative button text field
) : CampaignDetails()

@Serializable
data class SpinWheelContent(
    val availableSpinsText: String? = null,
    val rewardConfiguration: SpinWheelRewardConfig? = null,
    val userInteraction: SpinWheelUserInteraction? = null,
    val wheelConfiguration: SpinWheelWheelConfig? = null
)

@Serializable
data class SpinWheelRewardConfig(
    val rewardEnableBackdrop: Boolean? = null,
    val rewardPopupDescription: String? = null,
    val rewardPopupTitle: String? = null
)

@Serializable
data class SpinWheelUserInteraction(
    val hapticFeedback: Boolean? = null,
    val numberSpin: Int? = null
)

@Serializable
data class SpinWheelWheelConfig(
    val spinDirection: String? = null, // "clockwise" or "anti-clockwise"
    val totalSliceCount: Int? = null
)

@Serializable
data class WheelSlice(
    val id: String? = null,
    val parent: String? = null,
    val coupon: String? = null,
    val noPrize: Boolean? = null,
    val prizeLabel: String? = null,
    @SerialName("subText") val subText: String? = null, // Optional supporting text shown below the prize name
    val sliceMedia: String? = null,
    val weight: Int? = null,
    val styling: WheelSliceStyling? = null,
    val link: String? = null, // Redirect link for this specific prize (Button Redirect To)
    @SerialName("buttonCtaText") val buttonCtaText: String? = null, // Custom text for primary CTA button
    @SerialName("tncCtaText") val tncCtaText: String? = null, // Custom text for Terms & Conditions link
    @SerialName("termsAndConditions") val termsAndConditions: String? = null, // Content displayed when user clicks "Know More to Claim"
    val rewards: List<SliceReward>? = null // Array of reward configurations for this slice
)

// Slice Reward Configuration (per-slice reward display settings)
@Serializable
data class SliceReward(
    val id: String? = null,
    val sliceId: String? = null,
    val prizeName: String? = null,
    val couponCode: String? = null,
    val subText: String? = null,
    val buttonCta: String? = null,
    @SerialName("tNcCta") val tNcCta: String? = null,
    @SerialName("termsNConditions") val termsNConditions: String? = null,
    val link: String? = null,
    val sliceRewardMedia: String? = null,
    val styling: SliceRewardStyling? = null
)

@Serializable
data class SliceRewardStyling(
    val couponCodeCta: SliceRewardCtaStyling? = null,
    val cta: SliceRewardCtaStyling? = null,
    val priceLabel: SliceRewardTextConfig? = null,
    val subtitleText: SliceRewardTextConfig? = null
)

@Serializable
data class SliceRewardCtaStyling(
    val container: SliceRewardCtaContainer? = null,
    val cornerRadius: CornerRadius? = null,
    val margin: WheelMargin? = null,
    val text: SliceRewardCtaText? = null
)

@Serializable
data class SliceRewardCtaContainer(
    val alignment: String? = null,
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val borderWidth: Int? = null,
    val ctaFullWidth: Boolean? = null,
    val ctaWidth: Int? = null,
    val height: Int? = null
)

@Serializable
data class SliceRewardCtaText(
    val color: String? = null,
    val fontDecoration: List<String>? = null,
    val fontFamily: String? = null,
    @Serializable(with = NullableIntSerializer::class)
    val fontSize: Int? = null
)

@Serializable
data class SliceRewardTextConfig(
    val textStyle: SliceRewardTextStyle? = null
)

@Serializable
data class SliceRewardTextStyle(
    val color: String? = null,
    val fontDecoration: List<String>? = null,
    val fontFamily: String? = null,
    @Serializable(with = NullableIntSerializer::class)
    val fontSize: Int? = null,
    val margin: WheelMargin? = null,
    val textAlign: String? = null
)

// Styling Models (from Dashboard Styling Tab)
@Serializable
data class SpinWheelStyling(
    val spinTheWheel: SpinTheWheelMainStyling? = null,
    val rewardConfiguration: WheelRewardStyling? = null
)

@Serializable
data class SpinTheWheelMainStyling(
    val crossButton: WheelCrossButtonConfig? = null,
    val visualTextCommunication: WheelVisualTextStyling? = null,
    val wheelConfiguration: WheelConfigurationStyling? = null
)

@Serializable
data class WheelVisualTextStyling(
    val title: WheelTextStyleConfig? = null,
    val subtitle: WheelTextStyleConfig? = null,
    val availableSpinText: WheelAvailableSpinTextStyle? = null,
    val spinButton: WheelSpinButtonStyle? = null,
    val backdropColor: String? = null,
    val backdropOpacity: Int? = null
)

@Serializable
data class WheelAvailableSpinTextStyle(
    val textStyle: WheelTextStyleDetails? = null
)

@Serializable
data class WheelSpinButtonStyle(
    val container: WheelButtonContainerStyle? = null,
    val text: WheelButtonTextStyle? = null,
    val margin: WheelMargin? = null
)

@Serializable
data class WheelButtonContainerStyle(
    val alignment: String? = null,
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val borderWidth: Int? = null,
    val cornerRadius: CornerRadius? = null,
    val fullWidth: Boolean? = null,
    val height: Int? = null,
    val width: Int? = null
)

@Serializable
data class WheelButtonTextStyle(
    val color: String? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val fontWeight: String? = null,
    val fontStyle: String? = null,
    val fontDecoration: List<String>? = null
)

@Serializable
data class WheelConfigurationStyling(
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val borderWidth: Int? = null,
    val backgroundImage: String? = null,
    val backgroundImageOpacity: Float? = null,
    val size: Int? = null // Wheel diameter in dp - defaults to 300 if not set
)

@Serializable
data class WheelRewardStyling(
    val backdropColor: String? = null,
    val cardBackgroundColor: String? = null,
    val confetti: WheelConfettiConfig? = null,
    val crossButton: WheelCrossButtonConfig? = null,
    val title: WheelTextStyleConfig? = null,
    val subtitle: WheelTextStyleConfig? = null
)

@Serializable
data class WheelConfettiConfig(
    val selectedStyle: String? = null,
    val color: WheelButtonColors? = null,
    val image: String? = null,
    val margin: WheelMargin? = null,
    val padding: WheelMargin? = null
)

@Serializable
data class WheelCrossButtonConfig(
    val enabled: Boolean? = null,
    val selectedStyle: String? = null,
    val size: Int? = null,
    val color: WheelButtonColors? = null,
    val image: String? = null,
    val margin: WheelMargin? = null,
    val alignment: String? = null
)

@Serializable
data class WheelButtonColors(
    val cross: String? = null,
    val fill: String? = null,
    val stroke: String? = null
)

@Serializable
data class WheelMargin(
    val top: Int? = null,
    val bottom: Int? = null,
    val left: Int? = null,
    val right: Int? = null
)

@Serializable
data class WheelTextStyleConfig(
    val textStyle: WheelTextStyleDetails? = null
)

@Serializable
data class WheelTextStyleDetails(
    val color: String? = null,
    val fontFamily: String? = null,
    val fontSize: Int? = null,
    val fontWeight: String? = null,
    val fontStyle: String? = null,
    val fontDecoration: List<String>? = null,
    val textAlign: String? = null,
    val margin: WheelMargin? = null
)

@Serializable
data class WheelSliceStyling(
    val wheelStyling: WheelSliceWheelStyling? = null
)

@Serializable
data class WheelSliceWheelStyling(
    val color: WheelSliceColors? = null,
    val cornerRadius: CornerRadius? = null,
    val strokeWidth: Int? = null,
    val margin: WheelMargin? = null,
    val image: WheelSliceImageStyling? = null,
    val priceLabel: WheelSlicePriceLabelStyling? = null
)

@Serializable
data class WheelSliceColors(
    val background: String? = null,
    val stroke: String? = null
)

@Serializable
data class WheelSliceImageStyling(
    val cornerRadius: CornerRadius? = null,
    val rotation: Int? = null
)

@Serializable
data class WheelSlicePriceLabelStyling(
    val margin: WheelMargin? = null,
    val textStyle: WheelSliceTextStyle? = null
)

@Serializable
data class WheelSliceTextStyle(
    val font: String? = null,
    val fontSize: Int? = null,
    val color: String? = null
)

