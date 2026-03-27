package com.appversal.appstorys.utils

import android.util.Log
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

/**
 * Handles event tracking and reporting for the AppStorys SDK.
 *
 * This utility class encapsulates all HTTP-based event capture logic, allowing the SDK to
 * record user interactions (views, clicks, etc.) with campaigns to a remote tracking endpoint.
 *
 * ## Key Responsibilities
 *
 * ### Event Transmission
 * Sends structured event data to the AppStorys tracking service (`https://tracking.appstorys.co/capture-event`)
 * using HTTP POST requests. Each request includes:
 * - User ID (for tracking user journey across sessions)
 * - Campaign ID (to correlate events to specific campaigns)
 * - Event type (e.g., "viewed", "clicked", "dismissed")
 * - Optional metadata (contextual data about the interaction)
 *
 * ### Request Structure
 * Events are serialized as JSON objects with the following schema:
 * ```json
 * {
 *   "user_id": "string",
 *   "campaign_id": "string (optional)",
 *   "event": "string",
 *   "metadata": { "key": "value", ... } (optional)
 * }
 * ```
 *
 * ### Error Handling & Logging
 * - **Success**: Logs the HTTP response code for monitoring
 * - **Failure**: Catches and logs exceptions without crashing (fire-and-forget pattern)
 * - No network errors propagate to the SDK caller, ensuring events never block user interactions
 *
 * ## Usage Example
 *
 * ```kotlin
 * val tracker = EventTracker()
 * tracker.captureEvent(
 *     accessToken = "Bearer xyz123",
 *     userId = "user@example.com",
 *     campaignId = "campaign-456",
 *     event = "clicked",
 *     metadata = mapOf("button_label" to "Sign Up")
 * )
 * ```
 *
 * ## Thread Safety
 * Each call creates a new [OkHttpClient] instance, which is suitable for low-frequency
 * event tracking. For high-frequency scenarios, consider pooling the client in a future optimization.
 *
 * @see com.appversal.appstorys.AppStorys.trackEvents for SDK-level integration
 */
// Migration note: no in-repo usages after AppStorysCore.trackEvent() adoption.
// Kept (not deleted) for phased cleanup and reference.
/*
internal class EventTracker {
    /**
     * Captures and sends an event to the AppStorys tracking endpoint.
     *
     * This is a fire-and-forget operation: the method returns immediately without waiting
     * for the HTTP response. Errors are logged but do not propagate to the caller, ensuring
     * tracking failures never block user interactions or campaign rendering.
     *
     * ## Request Details
     *
     * - **Endpoint**: `https://tracking.appstorys.co/capture-event`
     * - **HTTP Method**: POST
     * - **Content-Type**: `application/json`
     * - **Authorization Header**: `Bearer <accessToken>`
     *
     * ## Parameters
     *
     * @param accessToken Bearer token for API authentication (e.g., "Bearer xyz123")
     * @param userId The current user ID (anonymous or identified) for tracking continuity
     * @param campaignId The campaign that triggered the event; `null` if not applicable
     * @param event The event name (e.g., "viewed", "clicked", "dismissed", "interacted")
     * @param metadata Map of contextual data to include with the event (e.g., button label, slide index)
     *                 Will be omitted from request JSON if empty
     *
     * ## Logging
     *
     * - **Success**: `Log.i("EventTracker", "Event captured: <event> - <http_code>")`
     * - **Error**: `Log.e("EventTracker", "Failed to capture event: <exception_message>")`
     *
     * ## Exception Safety
     *
     * All exceptions (network, JSON serialization, IO) are caught and logged internally.
     * This method will never throw an exception to the caller.
     *
     * @see com.appversal.appstorys.AppStorys.trackEvents for SDK-level event tracking orchestration
     */
    fun captureEvent(
        accessToken: String,
        userId: String,
        campaignId: String?,
        event: String,
        metadata: Map<String, Any>
    ) {
        val requestBody = JSONObject().apply {
            put("user_id", userId)
            campaignId?.let { put("campaign_id", it) }
            put("event", event)
            if (metadata.isNotEmpty()) {
                put("metadata", JSONObject(metadata))
            }
        }
        val client = OkHttpClient()
        val request = Request.Builder()
            .url("https://tracking.appstorys.co/capture-event")
            .post(requestBody.toString().toRequestBody("application/json".toMediaTypeOrNull()))
            .addHeader("Authorization", "Bearer $accessToken")
            .build()
        try {
            val response = client.newCall(request).execute()
            Log.i("EventTracker", "Event captured: $event - ${response.code}")
        } catch (e: Exception) {
            Log.e("EventTracker", "Failed to capture event: ${e.message}")
        }
    }
}
*/
