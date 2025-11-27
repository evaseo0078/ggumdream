// ?Œì¼ ?„ì¹˜: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    
    // ??Firebase Google Services ?ŒëŸ¬ê·¸ì¸ (?„ìˆ˜)
    id("com.google.gms.google-services")
}

dependencies {
    // ?”¥ Firebase BOM (ë²„ì „ ê´€ë¦? - ?´ì „???¤ë¥˜ê°€ ?¬ë˜ implementation ?¨ìˆ˜ ?•ì‹?¼ë¡œ ?˜ì •?˜ì—ˆ?µë‹ˆ??
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))

    // ??Firebase Analytics ë°?Auth SDK ì¶”ê?
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-auth-ktx")
}

android {
    namespace = "com.example.ggumdream"
    compileSdk = flutter.compileSdkVersion
    // Override to match plugins requiring NDK 27
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ggumdream"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
