plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // ✅ Плагин Google Services должен быть объявлен здесь (один раз)
    id("com.google.gms.google-services")
    // ✅ Flutter плагин — обязательно после Android и Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.untitled17"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.untitled17"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // ⚠️ Для публикации нужно будет добавить свой signingConfig
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// ⚠️ Этот вызов больше не нужен, он уже есть выше через plugins { ... }
// apply(plugin = "com.google.gms.google-services")

dependencies {
    // 🔥 Добавь нужные зависимости Firebase (можно управлять версиями через BoM)
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))

    // Firebase SDKs (Auth, Realtime Database, Analytics и т.д.)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-database")
    implementation("com.google.firebase:firebase-analytics")
}
