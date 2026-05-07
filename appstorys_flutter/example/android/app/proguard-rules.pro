# Flutter/Dart — keep all reflection targets
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── AppStorys shared-core ────────────────────────────────────────────────────
-keep class com.appversal.** { *; }
-dontwarn com.appversal.**

# ── Ktor (HTTP client used by shared-core) ───────────────────────────────────
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**

# ── Kotlinx Serialization ────────────────────────────────────────────────────
# Keep generated $serializer classes and companion objects
-keepattributes *Annotation*, InnerClasses
-keep,includedescriptorclasses class com.appversal.**$$serializer { *; }
-keepclassmembers @kotlinx.serialization.Serializable class com.appversal.** {
    *** Companion;
    *** INSTANCE;
    kotlinx.serialization.KSerializer serializer(...);
}
-keepclasseswithmembers class com.appversal.** {
    kotlinx.serialization.KSerializer serializer(...);
}
-keep class kotlinx.serialization.** { *; }
-dontwarn kotlinx.serialization.**

# ── OkHttp / OkIO (Ktor Android engine) ─────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# ── slf4j ────────────────────────────────────────────────────────────────────
-dontwarn org.slf4j.**

# ── Play Core ────────────────────────────────────────────────────────────────
-dontwarn com.google.android.play.core.**

# ── Kotlin coroutines ────────────────────────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
