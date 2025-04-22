plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Load key.properties file
import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Function to extract version information from pubspec.yaml
fun getVersionFromPubspec(field: String): String {
    val pubspecFile = File(project.rootDir.parentFile, "pubspec.yaml")
    val pubspecText = pubspecFile.readText()
    val versionPattern = "version:\\s*([^\\s]+)".toRegex()
    val versionMatch = versionPattern.find(pubspecText)
    val fullVersion = versionMatch?.groupValues?.get(1) ?: "1.0.0+1"
    
    return when(field) {
        "versionName" -> fullVersion.split("+")[0]
        "versionCode" -> fullVersion.split("+").getOrElse(1) { "1" }
        else -> ""
    }
}

android {
    namespace = "com.example.gxit_2025"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.gxit.app"
        minSdk = 23
        targetSdk = 34
        versionCode = getVersionFromPubspec("versionCode").toInt()
        versionName = getVersionFromPubspec("versionName")
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Disable minification for now to simplify build
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
}
