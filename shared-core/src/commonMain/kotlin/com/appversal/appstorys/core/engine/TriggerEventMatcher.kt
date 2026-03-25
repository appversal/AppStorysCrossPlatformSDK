package com.appversal.appstorys.core.engine

import com.appversal.appstorys.core.model.TriggerEvent
import com.appversal.appstorys.core.model.TriggerEventConfig

object TriggerEventMatcher {

    // Injected into _trackedEventNames when back is pressed.
    // Gates back_press campaigns -- they only render after this sentinel is present.
    const val BACK_PRESS_SENTINEL = "__back_press_triggered__"

    data class TrackedEventData(
        val eventName: String,
        val metadata: Map<String, Any>? = null
    )

    fun shouldShowCampaign(
        triggerEvent: TriggerEvent?,
        campaignId: String?,
        trackedEvents: Set<TrackedEventData>
    ): Boolean {
        if (triggerEvent == null) return true

        return when (triggerEvent) {
            is TriggerEvent.StringTrigger -> {
                if (triggerEvent.event.isEmpty()) return true
                val eventToMatch = if (triggerEvent.event == "viaAppStorys") {
                    "viaAppStorys${campaignId}"
                } else {
                    triggerEvent.event
                }
                trackedEvents.any { it.eventName == eventToMatch }
            }

            is TriggerEvent.ObjectTrigger -> {
                if (triggerEvent.event.isEmpty()) return true

                val isBackPressCampaign = triggerEvent.eventConfig.any { it.backPress == true }

                if (isBackPressCampaign) {
                    // Campaign is gated -- only evaluate after back is actually pressed
                    val backPressTriggered = trackedEvents.any {
                        it.eventName == BACK_PRESS_SENTINEL
                    }
                    if (!backPressTriggered) return false
                }

                // Find tracked events matching the campaign's event name
                val matchingEvents = trackedEvents.filter { it.eventName == triggerEvent.event }

                // Evaluate real conditions (excluding the back_press flag entry)
                matchingEvents.any { trackedEvent ->
                    matchesAllConditions(triggerEvent.eventConfig, trackedEvent.metadata)
                }
            }
        }
    }

    fun matchesAllConditions(
        conditions: List<TriggerEventConfig>,
        metadata: Map<String, Any>?
    ): Boolean {
        // Strip the back_press flag entry -- it is not a real condition
        val realConditions = conditions.filter { it.backPress == null }

        if (metadata == null && realConditions.isNotEmpty()) return false
        if (metadata == null) return true

        return realConditions.all { condition ->
            matchesCondition(condition, metadata)
        }
    }

    private fun matchesCondition(
        condition: TriggerEventConfig,
        metadata: Map<String, Any>
    ): Boolean {
        val key = condition.key ?: return false
        val conditionValue = condition.value ?: return false
        val metadataValue = metadata[key] ?: return false
        val metadataValueStr = metadataValue.toString()

        return when (condition.operator) {
            "eq" -> metadataValueStr == conditionValue
            "neq" -> metadataValueStr != conditionValue
            "gt" -> compareNumeric(metadataValueStr, conditionValue) { a, b -> a > b }
            "gte" -> compareNumeric(metadataValueStr, conditionValue) { a, b -> a >= b }
            "lt" -> compareNumeric(metadataValueStr, conditionValue) { a, b -> a < b }
            "lte" -> compareNumeric(metadataValueStr, conditionValue) { a, b -> a <= b }
            else -> false
        }
    }

    private fun compareNumeric(
        value1: String,
        value2: String,
        comparison: (Double, Double) -> Boolean
    ): Boolean {
        return try {
            comparison(value1.toDouble(), value2.toDouble())
        } catch (_: NumberFormatException) {
            comparison(value1.compareTo(value2).toDouble(), 0.0)
        }
    }
}