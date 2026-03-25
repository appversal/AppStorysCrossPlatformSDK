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
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ApiClientCampaignsJsonTest {

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun fetchCampaignsJson_on200_parsesAndCachesPayloadAndEtag() = runBlocking {
        val storage = InMemoryCampaignStore()
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = """
                        [
                          {
                            "id": "cmp-1",
                            "campaign_type": "UNK",
                            "details": null,
                            "position": "top",
                            "screen": "Home"
                          }
                        ]
                    """.trimIndent(),
                    status = HttpStatusCode.OK,
                    headers = headersOf(
                        HttpHeaders.ContentType to listOf(ContentType.Application.Json.toString()),
                        HttpHeaders.ETag to listOf("etag-123")
                    )
                )
            }) {
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false })
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = storage
        )

        val result = client.fetchCampaignsJson(accountId = "acct-1", cdnBaseUrl = "https://cdn.test")

        assertTrue(result is ApiResult.Success)
        assertEquals(1, result.data.size)
        assertEquals("cmp-1", result.data.first().id)
        assertEquals("/clients/acct-1/campaigns.json", capturedRequest?.url?.encodedPath)
        assertEquals("etag-123", storage.getString("campaigns_etag_acct-1"))
        assertTrue(!storage.getString("campaigns_json_acct-1").isNullOrBlank())
    }

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun fetchCampaignsJson_on304_usesCachedPayload() = runBlocking {
        val storage = InMemoryCampaignStore().apply {
            putString("campaigns_etag_acct-1", "etag-old")
            putString(
                "campaigns_json_acct-1",
                """
                    [
                      {
                        "id": "cmp-cached",
                        "campaign_type": "UNK",
                        "details": null,
                        "position": "middle",
                        "screen": "Home"
                      }
                    ]
                """.trimIndent()
            )
        }
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = "",
                    status = HttpStatusCode.NotModified,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(Json { ignoreUnknownKeys = true; explicitNulls = false })
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = storage
        )

        val result = client.fetchCampaignsJson(accountId = "acct-1", cdnBaseUrl = "https://cdn.test")

        assertTrue(result is ApiResult.Success)
        assertEquals("cmp-cached", result.data.first().id)
        assertEquals("etag-old", capturedRequest?.headers?.get(HttpHeaders.IfNoneMatch))
    }

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun fetchCampaignsJson_strCampaign_acceptsBooleanAsNumberOrString() = runBlocking {
        val client = ApiClient(
            httpClient = HttpClient(MockEngine {
                respond(
                    content = """
                        [
                          {
                            "id": "cmp-str-1",
                            "campaign_type": "STR",
                            "screen": "Home",
                            "details": [
                              {
                                "id": "group-1",
                                "name": "Stories",
                                "thumbnail": "https://cdn.test/thumb.jpg",
                                "order": 0,
                                "slides": [
                                  {
                                    "id": "slide-1",
                                    "image": "https://cdn.test/slide.jpg",
                                    "video": null,
                                    "link": "https://example.com",
                                    "button_text": "Open",
                                    "order": 0,
                                    "styling": {
                                      "fullWidthCta": 1,
                                      "cta": {
                                        "container": {
                                          "ctaFullWidth": "0",
                                          "height": 32
                                        }
                                      }
                                    }
                                  }
                                ],
                                "styling": {
                                  "crossButton": { "enabled": "1" },
                                  "soundToggle": { "enabled": 0 }
                                }
                              }
                            ]
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
            storage = InMemoryCampaignStore()
        )

        val result = client.fetchCampaignsJson(accountId = "acct-1", cdnBaseUrl = "https://cdn.test")
        assertTrue(result is ApiResult.Success)

        val storyCampaign = result.data.first()
        assertEquals("STR", storyCampaign.campaignType)
        assertNotNull(storyCampaign.details)
        assertTrue(true)
    }
}

private class InMemoryCampaignStore : KeyValueStore {
    private val strings = mutableMapOf<String, String>()
    private val booleans = mutableMapOf<String, Boolean>()

    override fun getString(key: String): String? = strings[key]

    override fun putString(key: String, value: String) {
        strings[key] = value
    }

    override fun getBoolean(key: String, default: Boolean): Boolean = booleans[key] ?: default

    override fun putBoolean(key: String, value: Boolean) {
        booleans[key] = value
    }
}



