package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed class CampaignDetails

@Serializable(with = CampaignDeserializer::class)
data class Campaign(
    val id: String?,
    @SerialName("campaign_type") val campaignType: String?,
    val details: CampaignDetails?,
    val position: String?,
    val screen: String?,
    @SerialName("trigger_event") val triggerEvent: TriggerEvent?
)
