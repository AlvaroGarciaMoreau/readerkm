pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val localPropertiesFile = settingsDir.resolve("local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { properties.load(it) }
        } else {
            // If missing, we might be running from the root or someone deleted it.
            // Let's try to find it in the current directory as well.
            val fallbackFile = file("local.properties")
            if (fallbackFile.exists()) {
                fallbackFile.inputStream().use { properties.load(it) }
            } else {
                throw GradleException("local.properties not found at ${localPropertiesFile.absolutePath}. Please run 'flutter pub get' in the project root.")
            }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties at ${localPropertiesFile.absolutePath}" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
