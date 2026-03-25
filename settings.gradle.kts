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
include(":shared-core")
