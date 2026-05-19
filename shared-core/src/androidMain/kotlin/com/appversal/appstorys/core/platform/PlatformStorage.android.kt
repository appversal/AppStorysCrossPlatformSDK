package com.appversal.appstorys.core.platform

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

private const val PREFS_NAME = "appstorys_core"

actual class PlatformStorage {
    companion object {
        /**
         * Optional explicit initializer. Call this from your Application.onCreate():
         *
         *     PlatformStorage.initialize(application)
         *
         * This avoids reflection-based lookups and is the recommended way to ensure a
         * stable Application context is available to the shared core on Android
         * (works reliably in multi-process, content-provider and instrumentation contexts).
         */
        @Volatile
        private var explicitAppContext: Context? = null

        /**
         * Initialize with an Application context. The parameter is nullable so callers
         * can explicitly clear a previously-initialized context by passing null.
         *
         * Preferred usage: call `PlatformStorage.initialize(application)` from
         * `Application.onCreate()` with a non-null Application instance.
         */
        fun initialize(appContext: Context?) {
            explicitAppContext = appContext?.applicationContext
        }

        /** Returns the explicitly initialized Application context if one was provided. */
        fun getInitializedContext(): Context? = explicitAppContext
    }

    private val prefs: SharedPreferences by lazy {
        getApplicationContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
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

actual fun getDeviceInfo(): Map<String, Any> {
    val prefs = getApplicationContext().getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    return mapOf(
        "platform" to "android",
        "os_version" to Build.VERSION.RELEASE,
        "api_level" to Build.VERSION.SDK_INT,
        "model" to Build.MODEL,
        "manufacturer" to Build.MANUFACTURER,
        "device_type" to "mobile",
        "app_version" to (prefs.getString("app_version", "") ?: ""),
        "package_name" to (prefs.getString("package_name", "") ?: ""),
        "language" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            getApplicationContext().resources.configuration.locales[0].language
        } else {
            @Suppress("DEPRECATION")
            getApplicationContext().resources.configuration.locale.language
        },
        "locale" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            getApplicationContext().resources.configuration.locales[0].toString()
        } else {
            @Suppress("DEPRECATION")
            getApplicationContext().resources.configuration.locale.toString()
        },
        "timezone" to java.util.TimeZone.getDefault().id,
        "screen_width_px" to (prefs.getString("screen_width", "0") ?: "0").toInt(),
        "screen_height_px" to (prefs.getString("screen_height", "0") ?: "0").toInt(),
        "screen_density" to (prefs.getString("screen_density", "0") ?: "0").toInt(),
        "orientation" to (prefs.getString("orientation", "portrait") ?: "portrait")
    )
}

/**
 * Returns an Application context for PlatformStorage to use. Prefer an explicit
 * call to [PlatformStorage.initialize] from the host Application; if that is
 * not available we fall back to the ActivityThread.currentApplication() reflection
 * lookup. If both fail we throw a clear error explaining the required action.
 */
private fun getApplicationContext(): Context {
    // Use explicit initializer if caller set it via PlatformStorage.initialize(app)
    PlatformStorage::class.java // no-op to reference class
    val fromCompanion = PlatformStorage.getInitializedContext()
    if (fromCompanion != null) return fromCompanion

    // Reflection fallback (best-effort)
    val reflected = runCatching {
        val activityThreadClass = Class.forName("android.app.ActivityThread")
        val currentApplication = activityThreadClass.getMethod("currentApplication")
        currentApplication.invoke(null) as? Context
    }.getOrNull()

    return reflected?.applicationContext ?: throw IllegalStateException(
        "PlatformStorage: Application context is not available.\n" +
            "Call PlatformStorage.initialize(application) from your Application.onCreate() before using the SDK.\n" +
            "Reflection fallback (ActivityThread.currentApplication) also failed — this commonly happens in content providers, instrumentation tests, or non-standard process startup.\n"
    )
}

