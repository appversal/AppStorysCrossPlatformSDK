package com.appversal.appstorys_flutter

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class AppstorysFlutterPluginTest {
    @Test
    fun onMethodCall_initializeWithoutAppId_returnsInvalidArgsError() {
        val plugin = AppstorysFlutterPlugin()
        val call = MethodCall("initialize", mapOf("accountId" to "acc-1"))
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).error("INVALID_ARGS", "Missing required argument: appId", null)
    }

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = AppstorysFlutterPlugin()
        val call = MethodCall("unknownMethod", null)
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).notImplemented()
    }

    @Test
    fun onMethodCall_setUserIdWithoutUserId_returnsInvalidArgsError() {
        val plugin = AppstorysFlutterPlugin()
        val call = MethodCall("setUserId", emptyMap<String, Any>())
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).error("INVALID_ARGS", "Missing required argument: userId", null)
    }

    @Test
    fun onMethodCall_setUserPropertiesWithoutAttributes_returnsInvalidArgsError() {
        val plugin = AppstorysFlutterPlugin()
        val call = MethodCall("setUserProperties", emptyMap<String, Any>())
        val result: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(call, result)

        Mockito.verify(result).error("INVALID_ARGS", "Missing required argument: attributes", null)
    }
}
