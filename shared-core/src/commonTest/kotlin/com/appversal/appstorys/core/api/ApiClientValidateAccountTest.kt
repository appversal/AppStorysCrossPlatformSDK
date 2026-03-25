package com.appversal.appstorys.core.api

import com.appversal.appstorys.core.model.TrackUserWebSocketRequest
import com.appversal.appstorys.core.model.ValidateAccountRequest
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
import kotlinx.serialization.json.JsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ApiClientValidateAccountTest {

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun validateAccount_hitsExpectedEndpoint_andParsesToken() = runBlocking {
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = "{\"access_token\":\"token-123\"}",
                    status = HttpStatusCode.OK,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(
                        Json {
                            ignoreUnknownKeys = true
                            explicitNulls = false
                        }
                    )
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = InMemoryKeyValueStore()
        )

        val result = client.validateAccount(
            accountId = "acct-1",
            request = ValidateAccountRequest(
                app_id = "app-1",
                account_id = "acct-1",
                user_id = "user-1",
                attributes = mapOf("os" to JsonPrimitive("android"))
            )
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("token-123", result.data.access_token)
        assertEquals("/acct-1/validate-account", capturedRequest?.url?.encodedPath)
    }

    @OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
    @Test
    fun getEligibleCampaigns_hitsExpectedEndpoint_andSendsBearerToken() = runBlocking {
        var capturedRequest: HttpRequestData? = null

        val client = ApiClient(
            httpClient = HttpClient(MockEngine { request ->
                capturedRequest = request
                respond(
                    content = """
                        {
                          "eligibleCampaignList": ["cmp-1", "cmp-2"],
                          "userId": "user-1",
                          "variants": [{"id": "cmp-1", "v_id": "v-1"}],
                          "personalization_data": {"name": "Alex"},
                          "test_user": true
                        }
                    """.trimIndent(),
                    status = HttpStatusCode.OK,
                    headers = headersOf(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                )
            }) {
                install(ContentNegotiation) {
                    json(
                        Json {
                            ignoreUnknownKeys = true
                            explicitNulls = false
                        }
                    )
                }
            },
            usersBaseUrl = "https://users.test/",
            storage = InMemoryKeyValueStore()
        )

        val result = client.getEligibleCampaigns(
            accountId = "acct-1",
            accessToken = "token-abc",
            request = TrackUserWebSocketRequest(
                user_id = "user-1",
                screenName = "Home"
            )
        )

        assertTrue(result is ApiResult.Success)
        assertEquals("/v2/acct-1/track-user-res", capturedRequest?.url?.encodedPath)
        assertEquals("Bearer token-abc", capturedRequest?.headers?.get("Authorization"))
        assertEquals(listOf("cmp-1", "cmp-2"), result.data.eligibleCampaignList)
    }
}

private class InMemoryKeyValueStore : KeyValueStore {
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




