group = "com.appversal.appstorys_flutter"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "2.2.20"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

plugins {
    id("com.android.library")
    id("kotlin-android")
}

android {
    namespace = "com.appversal.appstorys_flutter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 24
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

// ── Switch between local and JitPack shared-core ──
// Set useJitpackSharedCore=false in example/android/gradle.properties to use
// a locally-published shared-core (after running :shared-core:publishToMavenLocal).
val useJitpack = (project.findProperty("useJitpackSharedCore") as? String ?: "true").toBoolean()
val sharedCoreDep = if (useJitpack) {
    val version = project.findProperty("jitpackSharedCoreVersion") as? String ?: "v4.0.0-alpha26"
    println("📦 appstorys_flutter: using JitPack shared-core $version")
    "com.github.appversal.AppStorysCrossPlatformSDK:appstorys-core-android:$version"
} else {
    val version = project.findProperty("localSharedCoreVersion") as? String ?: "4.0.0-alpha04"
    println("📦 appstorys_flutter: using LOCAL shared-core $version")
    "com.github.appversal.AppStorysCrossPlatformSDK:appstorys-core-android:$version"
}

dependencies {
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation(sharedCoreDep)
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
