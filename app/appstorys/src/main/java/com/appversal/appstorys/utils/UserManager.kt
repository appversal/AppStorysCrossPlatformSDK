package com.appversal.appstorys.utils

import android.content.Context
import android.os.Build

/**
 * Manages user identification and persistence for the AppStorys SDK.
 *
 * This utility class is responsible for:
 * - Generating and storing anonymous user IDs (if no user is explicitly set)
 * - Managing the lifecycle of user identification (anonymous vs. identified)
 * - Persisting user identity to SharedPreferences for restoration across app restarts
 * - Providing public read-only access to current user ID and anonymous status
 *
 * ## Key Responsibilities
 *
 * ### Anonymous User ID Generation
 * When no user is provided during SDK initialization, `UserManager` automatically generates
 * a unique anonymous ID composed of the device's timestamp and model name (e.g., "1710500000000_pixel_6").
 * This ensures each device gets a consistent, trackable identifier even without explicit user setup.
 *
 * ### User Identification Transitions
 * Supports seamless transitions from anonymous to identified users via [setIdentifiedUser].
 * When an app identifies a known user (e.g., after login), the SDK can swap the anonymous ID
 * for a real user ID while maintaining all previous tracking context.
 *
 * ### Persistence Layer
 * All user state is persisted in SharedPreferences under the "AppStory" store, enabling recovery
 * of the same user ID across app sessions. This is critical for cohesive tracking across installs.
 *
 * ## Usage Example
 *
 * ```kotlin
 * val userManager = UserManager(context)
 *
 * // Get or create anonymous ID (auto-saves to SharedPreferences)
 * val anonymousId = userManager.getOrCreateAnonymousId()
 *
 * // Later, when user logs in, transition to identified user
 * userManager.setIdentifiedUser("user@example.com")
 *
 * // Check current state
 * val currentId = userManager.currentUserId
 * val isAnon = userManager.isAnonymous
 * ```
 *
 * @param context Android application context used to access SharedPreferences
 *
 * @see com.appversal.appstorys.AppStorys.initialize for SDK-level user setup integration
 */
// Migration note: no in-repo usages after user handling moved to AppStorysCore.
// Kept (not deleted) for phased cleanup and compatibility checks.
/*
internal class UserManager(context: Context) {
	private val prefs = context.getSharedPreferences("AppStory", Context.MODE_PRIVATE)

	companion object {
		private const val PREFS_USER_ID = "appstorys_user_id"
		private const val PREFS_IS_ANONYMOUS = "appstorys_is_anonymous"
	}

	var currentUserId: String = ""
		private set
	var isAnonymous: Boolean = true
		private set

	/**
	 * Retrieves or generates an anonymous user ID with automatic persistence.
	 *
	 * This method:
	 * 1. Checks if a user ID was previously saved in SharedPreferences
	 * 2. If found, restores it and updates [currentUserId] and [isAnonymous] status
	 * 3. If not found, generates a new anonymous ID (timestamp + device model) and persists it
	 *
	 * **Idempotent**: Calling this multiple times returns the same ID once generated.
	 *
	 * ## Generated ID Format
	 * Anonymous IDs follow the pattern: `{timestamp}_{device_model_lowercase}`
	 * - Example: `"1710500000000_pixel_6"`
	 * - Ensures uniqueness across devices while being human-readable
	 * - Device model names have spaces replaced with underscores and are lowercased
	 *
	 * @return The anonymous user ID (either newly generated or restored from persistence)
	 *
	 * @see [setIdentifiedUser] to transition from anonymous to identified user
	 */
	fun getOrCreateAnonymousId(): String {
		val saved = prefs.getString(PREFS_USER_ID, null)
		if (!saved.isNullOrEmpty()) {
			isAnonymous = prefs.getBoolean(PREFS_IS_ANONYMOUS, true)
			currentUserId = saved
			return saved
		}
		val timestamp = System.currentTimeMillis()
		val deviceModel = Build.MODEL.replace(" ", "_").lowercase()
		val generated = "${timestamp}_${deviceModel}"
		isAnonymous = true
		currentUserId = generated
		prefs.edit().apply {
			putString(PREFS_USER_ID, generated)
			putBoolean(PREFS_IS_ANONYMOUS, true)
			apply()
		}
		return generated
	}

	/**
	 * Transitions the user from anonymous to an identified/known user.
	 *
	 * This method:
	 * 1. Updates [currentUserId] to the provided user ID
	 * 2. Sets [isAnonymous] to `false` to indicate identified user
	 * 3. Persists both values to SharedPreferences for restoration across app sessions
	 *
	 * **Typical Use Case**: Called when a user logs in or authenticates, replacing the
	 * anonymous ID with their actual account identifier (e.g., email, UUID, or username).
	 *
	 * **Note**: This does NOT call any API reconciliation endpoint—that is handled by
	 * the SDK's higher-level [AppStorys.setUserId] method.
	 *
	 * @param userId The identified user ID to persist (e.g., "user@example.com" or "uuid-123")
	 *
	 * @see [getOrCreateAnonymousId] for the inverse operation (though users don't typically downgrade)
	 * @see com.appversal.appstorys.AppStorys.setUserId for the SDK-level integration with reconciliation
	 */
	fun setIdentifiedUser(userId: String) {
		currentUserId = userId
		isAnonymous = false
		prefs.edit().apply {
			putString(PREFS_USER_ID, userId)
			putBoolean(PREFS_IS_ANONYMOUS, false)
			apply()
		}
	}
}
*/
