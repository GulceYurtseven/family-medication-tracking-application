plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter plugininden sonra şu satırı ekleyin:
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // <--- BURAYA BUNU EKLEYİN
}

android {
    namespace = "com.example.ilac_takip"
    compileSdk = flutter.compileSdkVersion
    // ESKİ HALİ (Bunu silin veya yorum satırı yapın):
    // ndkVersion = flutter.ndkVersion

    // YENİ HALİ (Bunu yapıştırın):
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.ilac_takip"

        // ŞU KISMI DEĞİŞTİRİYORUZ:
        // minSdk = flutter.minSdkVersion (Bunu silin veya yorum satırı yapın)
        minSdk = 23 // <--- Yerine bunu yazın (Firebase için garanti çözüm)

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
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
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}