import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de publicació (Google Play). D'on ix, per ordre:
//  1. Codemagic: les variables CM_KEYSTORE_* que posa en el build quan el flux du `android_signing`.
//  2. En local: android/key.properties (storeFile, storePassword, keyAlias, keyPassword), fora del repo.
//  3. Si no n'hi ha cap, la clau de depuració: l'APK funciona però Google Play no l'accepta.
val propietatsClau = Properties().apply {
    val fitxer = rootProject.file("key.properties")
    if (fitxer.exists()) load(FileInputStream(fitxer))
}
val magatzemCodemagic: String? = System.getenv("CM_KEYSTORE_PATH")
val firmaPublicacio = magatzemCodemagic != null || propietatsClau.getProperty("storeFile") != null

android {
    namespace = "com.mamlabsfera.observatori_perlhorta"
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
        applicationId = "com.mamlabsfera.observatori_perlhorta"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (firmaPublicacio) {
            create("publicacio") {
                if (magatzemCodemagic != null) {
                    storeFile = file(magatzemCodemagic)
                    storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("CM_KEY_ALIAS")
                    keyPassword = System.getenv("CM_KEY_PASSWORD")
                } else {
                    storeFile = rootProject.file(propietatsClau.getProperty("storeFile"))
                    storePassword = propietatsClau.getProperty("storePassword")
                    keyAlias = propietatsClau.getProperty("keyAlias")
                    keyPassword = propietatsClau.getProperty("keyPassword")
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (firmaPublicacio) "publicacio" else "debug")
        }
    }
}

flutter {
    source = "../.."
}
