// Fix JVM target compatibility issues with plugins
subprojects {
    if (project.name in listOf("share_plus", "flutter_contacts", "url_launcher_android",
            "google_sign_in_android", "permission_handler_android", "path_provider_android",
            "shared_preferences_android", "geolocator_android", "cloud_firestore", 
            "firebase_auth", "firebase_core")) {
        
        // Apply consistent Java and Kotlin compiler settings
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
        
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_11.toString()
            }
        }
    }
} 