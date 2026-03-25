@file:Suppress("unused")

package com.appversal.appstorys.api

/**
 * DEPRECATED: All serializers have been migrated to shared-core.
 * This file provides backward compatibility re-exports only.
 * Import from com.appversal.appstorys.core.model directly.
 */

import kotlinx.serialization.KSerializer

/**
 * DEPRECATED: Use com.appversal.appstorys.core.model.NullableIntSerializer directly.
 * This is a re-export for backward compatibility.
 */
@Deprecated(
    "Import from com.appversal.appstorys.core.model directly",
    ReplaceWith("com.appversal.appstorys.core.model.NullableIntSerializer")
)
val NullableIntSerializer: KSerializer<Int?> = com.appversal.appstorys.core.model.NullableIntSerializer

/**
 * DEPRECATED: Use com.appversal.appstorys.core.model.NullableBooleanSerializer directly.
 * This is a re-export for backward compatibility.
 */
@Deprecated(
    "Import from com.appversal.appstorys.core.model directly",
    ReplaceWith("com.appversal.appstorys.core.model.NullableBooleanSerializer")
)
val NullableBooleanSerializer: KSerializer<Boolean?> = com.appversal.appstorys.core.model.NullableBooleanSerializer

