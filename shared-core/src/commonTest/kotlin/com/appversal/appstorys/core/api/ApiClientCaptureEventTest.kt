package com.appversal.appstorys.core.api

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.HttpRequestData
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ApiClientCaptureEventTest {

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun captureEvent_hitsExpectedEndpoint_andIncludesMetadata() = runBlocking {
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = "",
                    status = HttpStatusCode.OK,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false })
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = InMemoryEventStore(),
            trackingBaseUrl = "https://tracking.test/"
        )

        val result = client.captureEvent(
            accessToken = "token-event",
            userId = "user-1",
            campaignId = "cmp-1",
            event = "clicked",
            metadata = mapOf("button" to "signup", "count" to 42)
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("/capture-event", capturedRequest?.url?.encodedPath)
        assertEquals("Bearer token-event", capturedRequest?.headers?.get("Authorization"))
    }

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun captureEvent_withoutCampaignId_stillSucceeds() = runBlocking {
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = "",
                    status = HttpStatusCode.OK,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false })
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = InMemoryEventStore(),
            trackingBaseUrl = "https://tracking.test/"
        )

        val result = client.captureEvent(
            accessToken = "token-event",
            userId = "user-1",
            campaignId = null,
            event = "viewed"
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("/capture-event", capturedRequest?.url?.encodedPath)
    }
}

private class InMemoryEventStore : KeyValueStore {
    override fun getString(key: String): String? = null
    override fun putString(key: String, value: String) = Unit
    override fun getBoolean(key: String, default: Boolean): Boolean = default
    override fun putBoolean(key: String, value: Boolean) = Unit
}

