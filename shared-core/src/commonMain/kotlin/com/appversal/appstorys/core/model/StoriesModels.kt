package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class StoriesDetails(
    val groups: List<StoryGroup>?
) : CampaignDetails()

@Serializable
data class StoryGroup(
    val id: String?,
    val name: String?,
    val thumbnail: String?,
    val ringColor: String?,
    val nameColor: String?,
    val order: Int?,
    val slides: List<StorySlide>?,
    val styling: StoryGroupStyling?
)

@Serializable
data class StoryGroupStyling(
    val cornerRadius: CornerRadius?,
    val crossButton: StoryButtonConfig?,
    val name: StoryNameConfig?,
    val ringWidth: Int?,
    val share: StoryButtonConfig?,
    val size: Int?,
    val slideShowTime: Int?,
    val soundToggle: StorySoundToggleConfig?,
    val ringAndImageSpace: Int?,
    val storyGroupNotViewed: StoryGroupState?,
    val storyGroupViewed: StoryGroupState?
)

@Serializable
data class StoryGroupState(
    val ringColor: String?,
    val fontColor: String?,
    val fontSize: Int?,
    val fontDecoration: List<String>?
)

@Serializable
data class StoryButtonConfig(
    val colors: StoryButtonColors?,
    val color: StoryButtonColors?,
    val margin: StoryButtonMargin?,
    val image: String? = null,
    @Serializable(with = NullableBooleanSerializer::class)
    val enabled: Boolean? = null,
    val selectedStyle: String? = null,
    val size: Int? = null
)

@Serializable
data class StoryButtonColors(
    val cross: String?,
    val fill: String?,
    val stroke: String?
)

@Serializable
data class StoryButtonMargin(
    val right: Int?,
    val top: Int?
)

@Serializable
data class StoryNameConfig(
    val font: String?,
    val size: Int?
)

@Serializable
data class StorySoundToggleConfig(
    val mute: StoryButtonConfig?,
    val unmute: StoryButtonConfig?,
    val defaultSound: String? = null,
    @Serializable(with = NullableBooleanSerializer::class)
    val enabled: Boolean? = null
)

@Serializable
data class StorySlide(
    val id: String?,
    val parent: String?,
    val image: String?,
    val video: String?,
    val link: String?,
    @SerialName("button_text") val buttonText: String?,
    val order: Int?,
    val styling: StorySlideStyling?
)

@Serializable
data class StorySlideStyling(
    val borderWidth: Int?,
    val ctaAlignment: String?,
    val ctaBackground: StoryCtaBackground?,
    val ctaHeight: Int?,
    val ctaMargins: StoryCtaMargins?,
    val ctaText: StoryCtaText?,
    @Serializable(with = NullableBooleanSerializer::class)
    val fullWidthCta: Boolean?,
    @SerialName("editor_source") val editorSource: String? = null,
    val cta: StoryCtaConfig? = null
)

@Serializable
data class StoryCtaConfig(
    val container: StoryCtaContainer?,
    val cornerRadius: StoryCtaCornerRadius?,
    val margin: StoryCtaMargins?,
    val text: StoryCtaTextConfig?
)

@Serializable
data class StoryCtaContainer(
    val alignment: String?,
    val backgroundColor: String?,
    val borderColor: String?,
    val borderWidth: Int?,
    @Serializable(with = NullableBooleanSerializer::class)
    val ctaFullWidth: Boolean?,
    val ctaWidth: Int?,
    val height: Int?
)

@Serializable
data class StoryCtaCornerRadius(
    val topLeft: Int?,
    val topRight: Int?,
    val bottomLeft: Int?,
    val bottomRight: Int?
)

@Serializable
data class StoryCtaTextConfig(
    val color: String?,
    val fontDecoration: List<String>?,
    val fontFamily: String?,
    val fontSize: Int?
)

@Serializable
data class StoryCtaBackground(
    val backgroundColor: String?,
    val borderColor: String?
)

@Serializable
data class StoryCtaMargins(
    val bottom: Int?,
    val left: Int?,
    val right: Int?,
    val top: Int?
)

@Serializable
data class StoryCtaText(
    val fontColor: String?,
    val fontSize: Int?
)

@Serializable
data class CornerRadius(
    val bottomLeft: Int?,
    val bottomRight: Int?,
    val topLeft: Int?,
    val topRight: Int?
)

