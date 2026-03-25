package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ModalDetails(
    val id: String?,
    val modals: List<Modal>?,
    val name: String? = null
) : CampaignDetails()

@Serializable
data class Modal(
    @SerialName("id") val id: String?,
    @SerialName("modal_type") val modalType: String? = null,

    // ---------- CONTENT-BASED (CTA / CAROUSEL) ----------
    val content: ModalContent? = null,
    val styling: ModalStyling? = null,
    val screen: Int? = null,
    val name: String? = null,

    // ---------- FLAT MEDIA-ONLY MODAL ----------
    val chooseMediaType: ModalMedia? = null,
    val link: String? = null,
    val url: String? = null,
    val size: String? = null,
    val backgroundOpacity: String? = null,
    val borderRadius: Int? = null,
    val enableBackdrop: Boolean? = null,
    val enableCrossButton: Boolean? = null,
    val crossButtonImage: String? = null,
    val redirection: ModalRedirection? = null
)

@Serializable
data class ModalContent(
    val chooseMediaType: ModalMedia?,
    val titleText: String?,
    val subtitleText: String?,
    val primaryCtaText: String?,
    val primaryCtaRedirection: ModalRedirection?,
    val secondaryCtaText: String?,
    val secondaryCtaRedirection: ModalRedirection?,
    // Support an optional `set` of slides (some backends return `content.set` for carousel modals).
    // The slide objects use the same shape as ModalContent so we reuse the type recursively.
    val set: List<ModalContent>? = null,
    // Per-slide styling/overrides (optional). Some payloads include `styling` inside each slide.
    val styling: ModalStyling? = null,
    // Alternate/backward-compatible CTA keys that some backends use
    @SerialName("primaryCta") val primaryCta: String? = null,
    @SerialName("secondayCta") val secondayCta: String? = null,
    @SerialName("secondaryCta") val secondaryCtaAlt: String? = null,
    // Accept content-level enable flag (some payloads put this under content)
    @SerialName("enableCrossButton") val enableCrossButton: String? = null
)

@Serializable
data class ModalMedia(
    val type: String?, // image | gif | lottie
    val url: String?
)

@Serializable
data class ModalRedirection(
    val type: String?, // url | deeplink
    val url: String?,
    val value: String?,
    val key: String? = null,
    val pageName: String? = null
)

@Serializable
data class ModalStyling(
    val appearance: ModalAppearance?,
    val crossButton: ModalCrossButton? = null,
    val primaryCta: ModalCta? = null,
    val secondaryCta: ModalCta? = null,
    val title: ModalTextStyling? = null,
    val subTitle: ModalTextStyling? = null
)

@Serializable
data class ModalCrossButton(
    val default: ModalCrossButtonDefault? = null,
    val enableCrossButton: Boolean? = null,
    val uploadImage: ModalUploadImage? = null,
    // Alternative structure support (for legacy/image-only modals)
    val color: BannerColors? = null,  // Some payloads use "color" directly
    val colors: BannerColors? = null, // Some payloads use "colors"
    val enabled: Boolean? = null,
    val image: String? = null,        // Some payloads use "image" for cross button image
    val margin: ModalMargin? = null,
    val option: String? = null,
    val selectedStyle: String? = null,
    @Serializable(with = NullableIntSerializer::class)
    val size: Int? = null,
)

@Serializable
data class ModalCrossButtonDefault(
    val color: BannerColors? = null,
    val spacing: ModalSpacing? = null,
    val crossButtonImage: String? = null,
    val size: Int? = null
)

@Serializable
data class ModalUploadImage(
    val url: String? = null
)

@Serializable
data class ModalSpacing(
    val margin: ModalMargin? = null,
    val padding: ModalPadding? = null
)

@Serializable
data class ModalMargin(
    @Serializable(with = NullableIntSerializer::class)
    val top: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val right: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val bottom: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val left: Int? = null
)

// Add ModalPadding definition (same shape as ModalMargin) because some payloads use `padding` inside ModalAppearance
@Serializable
data class ModalPadding(
    @Serializable(with = NullableIntSerializer::class)
    val top: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val right: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val bottom: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val left: Int? = null
)

@Serializable
data class ModalCta(
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val containerStyle: ModalCtaContainer? = null,
    // Alternate field name used by some backends
    val container: ModalCtaContainer? = null,
    val cornerRadius: ModalCtaCornerRadius? = null,
    val occupyFullWidth: String? = null,
    val spacing: ModalSpacing? = null,
    // Alternate: some backends send margin directly instead of spacing.margin
    val margin: ModalMargin? = null,
    val textColor: String? = null,
    val textStyle: ModalTextStyle? = null,
    // Alternate field name used by some backends
    val text: ModalCtaText? = null
)

@Serializable
data class ModalCtaContainer(
    val alignment: String? = null,
    val borderWidth: Int? = null,
    val ctaWidth: Int? = null,
    val height: Int? = null,
    // Additional fields that some backends put inside container
    val backgroundColor: String? = null,
    val borderColor: String? = null,
    val ctaFullWidth: Boolean? = null
)

@Serializable
data class ModalCtaCornerRadius(
    val topLeft: Int? = null,
    val topRight: Int? = null,
    val bottomLeft: Int? = null,
    val bottomRight: Int? = null
)

@Serializable
data class ModalTextStyle(
    val font: String? = null,
    val size: Int? = null
)

// Alternate text styling format used by some backends (inside "text" key)
@Serializable
data class ModalCtaText(
    val color: String? = null,
    val fontSize: Int? = null,
    val fontFamily: String? = null,
    val fontDecoration: List<String>? = null
)

@Serializable
data class ModalTextStyling(
    val alignment: String? = null,
    val textAlign: String? = null,  // Alternate field name
    val color: String? = null,
    val font: String? = null,
    val fontFamily: String? = null,  // Alternate field name
    val fontStyle: String? = null,
    val size: Int? = null,
    val fontSize: Int? = null,  // Alternate field name
    val fontDecoration: List<String>? = null  // Support bold, italic, underline
)

@Serializable
data class ModalAppearance(
    val dimension: ModalDimension? = null,
    val cornerRadius: ModalCornerRadius? = null,
    val backdrop: ModalBackdrop? = null,
    val enableBackdrop: Boolean? = null,
    val padding: ModalPadding? = null,
    val ctaDisplay: String? = null,
    // Background color for modal content area
    val backgroundColor: String? = null,
    // Accept alternate flat keys used by some backends
    val backdropColor: String? = null,
    val backdropOpacity: String? = null,
)

@Serializable
data class ModalBackdrop(
    val color: String? = null,
    // keep as String? to accept numeric or string representations from backend
    val opacity: String? = null
)

@Serializable
data class ModalDimension(
    val height: String? = null,
    val borderWidth: String? = null
)

@Serializable
data class ModalCornerRadius(
    @Serializable(with = NullableIntSerializer::class)
    val topLeft: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val topRight: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val bottomLeft: Int? = null,
    @Serializable(with = NullableIntSerializer::class)
    val bottomRight: Int? = null
)

