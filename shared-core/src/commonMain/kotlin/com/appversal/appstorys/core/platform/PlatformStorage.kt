package com.appversal.appstorys.core.platform

expect class PlatformStorage {
    fun getString(key: String): String?
    fun putString(key: String, value: String)
    fun getBoolean(key: String, default: Boolean): Boolean
    fun putBoolean(key: String, value: Boolean)
    fun getInt(key: String, default: Int): Int
    fun putInt(key: String, value: Int)
}

expect fun currentTimeMillis(): Long
expect fun logDebug(tag: String, message: String)
expect fun logError(tag: String, message: String)

