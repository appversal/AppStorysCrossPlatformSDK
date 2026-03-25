package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

@Serializable
data class WidgetDetails(
    val id: String?,
    val type: String?,
    val width: Int?,
    val height: Int?,
    @SerialName("widget_images") val widgetImages: List<WidgetImage>?,
    val campaign: String?,
    val screen: String?,
    val styling: WidgetStyling?
) : CampaignDetails()

@Serializable
data class WidgetStyling(
    val topMargin: Int?,
    val leftMargin: Int?,
    val rightMargin: Int?,
    val bottomMargin: Int?,
    val topLeftRadius: Int?,
    val topRightRadius: Int?,
    val bottomLeftRadius: Int?,
    val bottomRightRadius: Int?,
)

@Serializable
data class WidgetImage(
    val id: String?,
    val image: String?,
    val link: JsonElement?,
    val order: Int?,
    val lottie_data: String?,
)

@Serializable
data class FloaterDetails(
    val id: String?,
    val image: String?,
    val width: Int?,
    val height: Int?,
    val link: String?,
    val position: String?,
    val campaign: String?,
    val styling: FloaterStyling?,
    val lottie_data: String?,
) : CampaignDetails()

@Serializable
data class FloaterStyling(
    val topLeftRadius: String?,
    val topRightRadius: String?,
    val bottomLeftRadius: String?,
    val bottomRightRadius: String?,
    val floaterBottomPadding: String?,
    val floaterRightPadding: String?,
    val floaterLeftPadding: String?,
)

