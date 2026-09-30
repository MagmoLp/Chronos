import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    // With android.builtInKotlin=false it applies the Kotlin Gradle plugin itself.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: android/key.properties (never committed, see docs/ANDROID_BUILD.md).
// Keys: storeFile (relative to android/app/ or absolute), storePassword, keyAlias, keyPassword.
val keystorePropertiesFile: File = rootProject.file("key.properties")
val hasReleaseKeystore: Boolean = keystorePropertiesFile.exists()
val keystoreProperties =
    Properties().apply {
        if (hasReleaseKeystore) {
            keystorePropertiesFile.inputStream().use { load(it) }
        }
    }

fun keystoreProperty(name: String): String =
    keystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException("android/key.properties is missing the property '$name'.")

val releaseTaskRequested: Boolean =
    gradle.startParameter.taskNames.any { it.contains("release", ignoreCase = true) }
if (!hasReleaseKeystore && releaseTaskRequested) {
    logger.warn(
        "WARNING: android/key.properties not found. The release build is signed with the " +
            "DEBUG key and must not be uploaded to Google Play (see docs/ANDROID_BUILD.md).",
    )
}

android {
    // Never change namespace/applicationId: Play updates and the v1 data migration depend on it.
    namespace = "com.paulhuebner.chronos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications uses java.time for scheduled notifications,
        // which needs core library desugaring below API 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.paulhuebner.chronos"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Taken from `version:` in pubspec.yaml (2.0.0+2 -> versionName 2.0.0, versionCode 2).
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperty("keyAlias")
                keyPassword = keystoreProperty("keyPassword")
                storeFile = file(keystoreProperty("storeFile"))
                storePassword = keystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Without android/key.properties (fresh clone, CI) fall back to the debug key so that
            // `flutter build` still works; such a build can never replace the Play version.
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            // R8 (minify + resource shrinking) is switched on by the Flutter Gradle plugin for
            // release builds; it also picks up proguard-rules.pro from this directory.
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Minimum version required by flutter_local_notifications 22.3.1.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
