package com.appversal.appstorys.core.api

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.HttpRequestData
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.content.OutgoingContent
import io.ktor.http.headersOf
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ApiClientTooltipIdentifyTest {

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun tooltipIdentify_hitsExpectedEndpoint_andSendsMultipartPayload() = runBlocking {
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
            backendBaseUrl = "https://backend.test/",
            storage = InMemoryTooltipStore()
        )

        val result = client.tooltipIdentify(
            accessToken = "token-tooltip",
            userId = "user-1",
            screenName = "Home",
            childrenJson = "[{\"id\":\"view1\"}]",
            screenshotBytes = byteArrayOf(1, 2, 3, 4),
            screenshotFileName = "shot.png"
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("/api/v1/appinfo/identify-elements/", capturedRequest?.url?.encodedPath)
        assertEquals("Bearer token-tooltip", capturedRequest?.headers?.get(HttpHeaders.Authorization))
        val outgoing: OutgoingContent? = capturedRequest?.body
        val multipartContentType = outgoing?.contentType?.toString()
        assertTrue(
            multipartContentType?.startsWith("multipart/form-data") == true,
            "Expected multipart/form-data content type"
        )
    }
}

private class InMemoryTooltipStore : KeyValueStore {
    override fun getString(key: String): String? = null
    override fun putString(key: String, value: String) = Unit
    override fun getBoolean(key: String, default: Boolean): Boolean = default
    override fun putBoolean(key: String, value: Boolean) = Unit
}



