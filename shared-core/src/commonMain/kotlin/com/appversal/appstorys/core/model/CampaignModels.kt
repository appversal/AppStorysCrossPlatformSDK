package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
abstract class CampaignDetails

@Serializable
data class Campaign(
    val id: String?,
    @SerialName("campaign_type") val campaignType: String?,
    val details: CampaignDetails?,
    val position: String?,
    val screen: String?,
    @SerialName("trigger_event") val triggerEvent: TriggerEvent?
)

