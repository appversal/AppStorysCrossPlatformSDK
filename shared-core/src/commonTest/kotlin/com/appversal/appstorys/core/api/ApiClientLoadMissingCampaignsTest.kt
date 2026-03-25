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

class ApiClientLoadMissingCampaignsTest {

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun loadMissingCampaigns_hitsExpectedEndpoint_andReturnsCampaigns() = runBlocking {
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = """
                        [
                          {
                            "id": "cmp-missing-1",
                            "campaign_type": "UNK",
                            "details": null,
                            "position": "top",
                            "screen": "Home"
                          }
                        ]
                    """.trimIndent(),
                    status = HttpStatusCode.OK,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false })
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = InMemoryLoadStore()
        )

        val result = client.loadMissingCampaigns(
            accessToken = "token-load",
            campaignIds = listOf("cmp-missing-1", "cmp-missing-2")
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("/load-campaign-data", capturedRequest?.url?.encodedPath)
        assertEquals("Bearer token-load", capturedRequest?.headers?.get("Authorization"))
        assertEquals("cmp-missing-1", result.data.first().id)
    }
}

private class InMemoryLoadStore : KeyValueStore {
    override fun getString(key: String): String? = null
    override fun putString(key: String, value: String) = Unit
    override fun getBoolean(key: String, default: Boolean): Boolean = default
    override fun putBoolean(key: String, value: Boolean) = Unit
}

