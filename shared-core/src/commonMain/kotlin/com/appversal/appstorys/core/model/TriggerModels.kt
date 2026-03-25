package com.appversal.appstorys.core.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed class TriggerEvent {
    @Serializable
    data class StringTrigger(val event: String) : TriggerEvent()

    @Serializable
    data class ObjectTrigger(
        val event: String,
        @SerialName("event_config") val eventConfig: List<TriggerEventConfig> = emptyList()
    ) : TriggerEvent()
}

@Serializable
data class TriggerEventConfig(
    val key: String? = null,
    val operator: String? = null,
    val value: String? = null,
    @SerialName("back_press") val backPress: Boolean? = null
)