plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "whisperpush.yangtze.asia"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "whisperpush.yangtze.asia"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        val storeFileProp = project.properties["RELEASE_STORE_FILE"] as String?
        val storePasswordProp = project.properties["RELEASE_STORE_PASSWORD"] as String?
        val keyAliasProp = project.properties["RELEASE_KEY_ALIAS"] as String?
        val keyPasswordProp = project.properties["RELEASE_KEY_PASSWORD"] as String?
        
        if (!storeFileProp.isNullOrEmpty() && !storePasswordProp.isNullOrEmpty() && 
            !keyAliasProp.isNullOrEmpty() && !keyPasswordProp.isNullOrEmpty()) {
            create("release") {
                storeFile = file(storeFileProp)
                storePassword = storePasswordProp
                keyAlias = keyAliasProp
                keyPassword = keyPasswordProp
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
