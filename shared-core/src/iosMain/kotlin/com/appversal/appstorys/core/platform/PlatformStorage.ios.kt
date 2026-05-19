package com.appversal.appstorys.core.platform

import platform.Foundation.NSDate
import platform.Foundation.NSLog
import platform.Foundation.NSUserDefaults
import platform.Foundation.timeIntervalSince1970
import platform.UIKit.UIDevice
import platform.UIKit.UIDeviceOrientation
import platform.UIKit.UIScreen

actual class PlatformStorage {
    private val defaults = NSUserDefaults.standardUserDefaults

    actual fun getString(key: String): String? = defaults.stringForKey(key)

    actual fun putString(key: String, value: String) {
        defaults.setObject(value, forKey = key)
    }

    actual fun getBoolean(key: String, default: Boolean): Boolean {
        return if (defaults.objectForKey(key) != null) defaults.boolForKey(key) else default
    }

    actual fun putBoolean(key: String, value: Boolean) {
        defaults.setBool(value, forKey = key)
    }

    actual fun getInt(key: String, default: Int): Int {
        return if (defaults.objectForKey(key) != null) defaults.integerForKey(key).toInt() else default
    }

    actual fun putInt(key: String, value: Int) {
        defaults.setInteger(value.toLong(), forKey = key)
    }
}

actual fun currentTimeMillis(): Long = (NSDate().timeIntervalSince1970 * 1000).toLong()

actual fun logDebug(tag: String, message: String) {
    NSLog("D/$tag: $message")
}

actual fun logError(tag: String, message: String) {
    NSLog("E/$tag: $message")
}

actual fun getDeviceInfo(): Map<String, Any> {
    val device = UIDevice.currentDevice
    val screen = UIScreen.mainScreen
    val scale = screen.scale
    val bounds = screen.bounds
    val widthPx = (bounds.useContents { size.width } * scale).toInt()
    val heightPx = (bounds.useContents { size.height } * scale).toInt()
    val densityDpi = (scale * 160).toInt()
    val orientation = when (device.orientation) {
        UIDeviceOrientation.UIDeviceOrientationLandscapeLeft,
        UIDeviceOrientation.UIDeviceOrientationLandscapeRight -> "landscape"
        else -> "portrait"
    }
    val defaults = NSUserDefaults.standardUserDefaults
    return mapOf(
        "platform" to "ios",
        "os_version" to device.systemVersion,
        "model" to device.model,
        "manufacturer" to "Apple",
        "device_type" to "mobile",
        "language" to (platform.Foundation.NSLocale.currentLocale.languageCode ?: ""),
        "locale" to platform.Foundation.NSLocale.currentLocale.localeIdentifier,
        "timezone" to platform.Foundation.NSTimeZone.defaultTimeZone.name,
        "screen_width_px" to widthPx,
        "screen_height_px" to heightPx,
        "screen_density" to densityDpi,
        "orientation" to orientation,
        "app_version" to (defaults.stringForKey("app_version") ?: ""),
        "package_name" to (defaults.stringForKey("package_name") ?: "")
    )
}

