import org.jetbrains.kotlin.gradle.dsl.JvmTarget

val ctsReleaseKeystorePath = System.getenv("CTS_ANDROID_KEYSTORE_PATH")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.combinedtechnicalservices.miningaxleinspection"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.combinedtechnicalservices.miningaxleinspection"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!ctsReleaseKeystorePath.isNullOrBlank()) {
            create("ctsRelease") {
                storeFile = file(ctsReleaseKeystorePath)
                storePassword = System.getenv("CTS_ANDROID_STORE_PASSWORD")
                    ?: error("CTS_ANDROID_STORE_PASSWORD is required for release signing.")
                keyAlias = System.getenv("CTS_ANDROID_KEY_ALIAS")
                    ?: error("CTS_ANDROID_KEY_ALIAS is required for release signing.")
                keyPassword = System.getenv("CTS_ANDROID_KEY_PASSWORD")
                    ?: error("CTS_ANDROID_KEY_PASSWORD is required for release signing.")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (ctsReleaseKeystorePath.isNullOrBlank()) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("ctsRelease")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}

val verifyReleasePluginRegistrant by tasks.registering {
    group = "verification"
    description = "Fails release builds when Flutter plugin registration is missing."

    doLast {
        val registrant = layout.projectDirectory
            .file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
            .asFile
        check(registrant.isFile) {
            "GeneratedPluginRegistrant.java is missing. Build release APKs with " +
                "`flutter build apk --release`, never `gradlew assembleRelease` " +
                "from an ungenerated workspace."
        }

        val source = registrant.readText()
        val requiredPlugins = listOf(
            "com.github.dart_lang.jni.JniPlugin",
            "com.github.dart_lang.jni_flutter.JniFlutterPlugin",
            "com.tekartik.sqflite.SqflitePlugin",
        )
        requiredPlugins.forEach { pluginClass ->
            check(source.contains(pluginClass)) {
                "GeneratedPluginRegistrant.java does not register $pluginClass. " +
                    "Run `flutter clean && flutter pub get` before rebuilding."
            }
        }
        check(!source.contains("dev.flutter.plugins.integration_test")) {
            "GeneratedPluginRegistrant.java contains the integration-test plugin. " +
                "Rebuild from a clean production target before releasing."
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(verifyReleasePluginRegistrant)
}
