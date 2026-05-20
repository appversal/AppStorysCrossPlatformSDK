plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    id("maven-publish")
    id("kotlin-parcelize")
}

android {
    namespace = "com.appversal.appstorys"
    compileSdk = 34
    publishing {
        singleVariant("release") {
            withSourcesJar()
        }
    }
    defaultConfig {
        minSdk = 22
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = libs.versions.composeCompiler.get()
    }
}

// ── Read the switch property from gradle.properties ──
val useJitpackSharedCore = (project.findProperty("useJitpackSharedCore") as? String ?: "false").toBoolean()
val sharedCoreVersion = project.findProperty("sharedCoreVersion") as? String ?: "v4.0.0-alpha30"

dependencies {
    // ── Conditional shared-core dependency ──
    if (useJitpackSharedCore) {
        implementation("com.github.appversal.AppStorysCrossPlatformSDK:appstorys-core-android:$sharedCoreVersion")
    } else {
        implementation(project(":shared-core"))
    }
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.material3)
    implementation(libs.coil.compose)
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.5")
    implementation("com.google.accompanist:accompanist-coil:0.15.0")
    implementation("androidx.compose.ui:ui-text-google-fonts")
    implementation("com.airbnb.android:lottie-compose:6.0.0")
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)

    implementation("androidx.lifecycle:lifecycle-process:2.8.7")

    implementation(libs.gson)
    implementation(libs.kotlinx.serialization.json)
    implementation("io.ktor:ktor-client-core:2.3.12")
    implementation("io.ktor:ktor-client-okhttp:2.3.12")
    implementation("io.ktor:ktor-client-content-negotiation:2.3.12")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.12")
    implementation("io.ktor:ktor-client-logging:2.3.12")
    implementation(libs.coil.gif)
    implementation(libs.androidx.activity.ktx)
    implementation(libs.exoplayer.ui)
    implementation(libs.exoplayer.core)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.activity.compose)
    implementation(libs.androidx.foundation)
    implementation(libs.androidx.media3.exoplayer)
    implementation(libs.androidx.media3.ui)
    implementation(libs.androidx.media3.exoplayer.dash)
    implementation(libs.androidx.media3.exoplayer.hls)
    implementation(libs.androidx.glance.preview)
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                groupId = "com.appversal"
                artifactId = "appstorys"
                version = "3.7.2"
            }
        }
    }
}