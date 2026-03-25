package com.appversal.appstorys.core.platform

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

private const val PREFS_NAME = "appstorys_core"

actual class PlatformStorage {
    private val prefs: SharedPreferences by lazy {
        resolveApplicationContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    actual fun getString(key: String): String? = prefs.getString(key, null)

    actual fun putString(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    actual fun getBoolean(key: String, default: Boolean): Boolean = prefs.getBoolean(key, default)

    actual fun putBoolean(key: String, value: Boolean) {
        prefs.edit().putBoolean(key, value).apply()
    }

    actual fun getInt(key: String, default: Int): Int = prefs.getInt(key, default)

    actual fun putInt(key: String, value: Int) {
        prefs.edit().putInt(key, value).apply()
    }
}

actual fun currentTimeMillis(): Long = System.currentTimeMillis()

actual fun logDebug(tag: String, message: String) {
    Log.d(tag, message)
}

actual fun logError(tag: String, message: String) {
    Log.e(tag, message)
}

private fun resolveApplicationContext(): Context {
    val context = runCatching {
        val activityThreadClass = Class.forName("android.app.ActivityThread")
        val currentApplication = activityThreadClass.getMethod("currentApplication")
        currentApplication.invoke(null) as? Context
    }.getOrNull()

    return context?.applicationContext
        ?: throw IllegalStateException("PlatformStorage requires an Application context")
}

