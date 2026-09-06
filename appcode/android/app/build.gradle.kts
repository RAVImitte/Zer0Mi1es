import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "app.zeromiles"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.zeromiles"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (keystorePropertiesFile.exists()) {
        signingConfigs.create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storePassword = keystoreProperties.getProperty("storePassword")
            val storeFilePath = keystoreProperties.getProperty("storeFile")
            require(!storeFilePath.isNullOrBlank()) {
                "storeFile is required in android/key.properties"
            }
            val store = File(storeFilePath)
            // Relative paths are from the android/ directory (next to key.properties).
            storeFile = if (store.isAbsolute) store else rootProject.file(storeFilePath)
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Attach only when key.properties exists so configure (flutter test) still succeeds.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

fun isReleasePackagingTask(taskName: String): Boolean =
    taskName.contains("Release") &&
        (
            taskName.startsWith("package") ||
                (taskName.startsWith("sign") && taskName.contains("Bundle")) ||
                (taskName.startsWith("bundle") && taskName.endsWith("Release"))
        )

fun requireReleaseKeyProperties() {
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties is required to package a signed release. " +
                "See docs/releases/SIGNING.md.",
        )
    }
}

// AGP skips validateSigningRelease unless signing is ready, then FinalizeBundleTask
// writes an unsigned app-release.aab that Flutter accepts. Fail packaging instead.
gradle.taskGraph.whenReady {
    if (allTasks.any { isReleasePackagingTask(it.name) }) {
        requireReleaseKeyProperties()
    }
}

tasks.configureEach {
    if (isReleasePackagingTask(name)) {
        doFirst { requireReleaseKeyProperties() }
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
