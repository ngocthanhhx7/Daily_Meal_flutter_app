import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val releaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
if (releaseRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "Release signing is not configured. Create android/key.properties; see README.md."
    )
}
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

val facebookPropertiesFile = rootProject.file("facebook.properties")
val facebookProperties = Properties()
if (facebookPropertiesFile.exists()) {
    FileInputStream(facebookPropertiesFile).use(facebookProperties::load)
}
val facebookAppId = providers.gradleProperty("facebookAppId")
    .orElse(providers.environmentVariable("FACEBOOK_APP_ID"))
    .orNull
    ?: facebookProperties.getProperty("appId")
    ?: "3483710358450589"
val facebookClientToken = providers.gradleProperty("facebookClientToken")
    .orElse(providers.environmentVariable("FACEBOOK_CLIENT_TOKEN"))
    .orNull
    ?: facebookProperties.getProperty("clientToken")
if (releaseRequested && facebookClientToken.isNullOrBlank()) {
    throw GradleException(
        "Facebook Android Client Token is missing. Create android/facebook.properties; see README.md."
    )
}

android {
    namespace = "com.dailymeal.daily_meal_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dailymeal.daily_meal_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "Daily Meal")
        resValue("string", "facebook_app_id", facebookAppId)
        resValue("string", "fb_login_protocol_scheme", "fb$facebookAppId")
        resValue(
            "string",
            "facebook_client_token",
            facebookClientToken ?: "FACEBOOK_CLIENT_TOKEN_NOT_CONFIGURED"
        )
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
