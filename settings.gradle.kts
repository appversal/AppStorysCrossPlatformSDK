pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        maven {
            url = uri("https://jitpack.io")
            credentials.username = "jp_bj3d32o7qm68rsvspu9bi04dsr"
        }
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://jitpack.io")
            credentials.username = "jp_bj3d32o7qm68rsvspu9bi04dsr"
        }
    }
}

include(":app")
include(":app:appstorys")


// ── Conditionally include shared-core based on the switch in gradle.properties ──
val useJitpack = (settings.providers.gradleProperty("useJitpackSharedCore").orNull ?: "false").toBoolean()
if (!useJitpack) {
    include(":shared-core")
    println("📦 shared-core: using LOCAL module")
} else {
    println("📦 shared-core: using JitPack version")
}