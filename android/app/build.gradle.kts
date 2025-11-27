// 파일 위치: android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    
    // ✅ Firebase Google Services 플러그인 (필수)
    id("com.google.gms.google-services")
}

dependencies {
    // 🔥 Firebase BOM (버전 관리) - 이전에 오류가 났던 implementation 함수 형식으로 수정되었습니다.
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // ✅ Firebase Analytics 및 Auth SDK 추가
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
