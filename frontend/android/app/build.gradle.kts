import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// Production Release Signing Configuration & Fail-Fast Validation
// ---------------------------------------------------------------------------
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreProperties = keystorePropertiesFile.exists() && keystorePropertiesFile.isFile

if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun resolveKeystoreFile(path: String?): java.io.File? {
    if (path.isNullOrBlank()) return null
    val rootResolved = rootProject.file(path)
    if (rootResolved.exists() && rootResolved.isFile) return rootResolved
    val directResolved = file(path)
    if (directResolved.exists() && directResolved.isFile) return directResolved
    return rootResolved // return for diagnostic reporting in error messages
}

android {
    namespace = "com.tactilearchive.app"
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
        // Application ID
        applicationId = "com.tactilearchive.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                val keyAliasVal = keystoreProperties.getProperty("keyAlias")
                val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
                val storePasswordVal = keystoreProperties.getProperty("storePassword")
                val storeFileProp = keystoreProperties.getProperty("storeFile")

                if (keyAliasVal.isNullOrBlank()) {
                    throw GradleException("[RELEASE SIGNING CONFIG ERROR] 'keyAlias' is missing or blank in ${keystorePropertiesFile.absolutePath}")
                }
                if (keyPasswordVal.isNullOrBlank()) {
                    throw GradleException("[RELEASE SIGNING CONFIG ERROR] 'keyPassword' is missing or blank in ${keystorePropertiesFile.absolutePath}")
                }
                if (storePasswordVal.isNullOrBlank()) {
                    throw GradleException("[RELEASE SIGNING CONFIG ERROR] 'storePassword' is missing or blank in ${keystorePropertiesFile.absolutePath}")
                }
                if (storeFileProp.isNullOrBlank()) {
                    throw GradleException("[RELEASE SIGNING CONFIG ERROR] 'storeFile' is missing or blank in ${keystorePropertiesFile.absolutePath}")
                }

                val resolvedFile = resolveKeystoreFile(storeFileProp)
                if (resolvedFile == null || !resolvedFile.exists() || !resolvedFile.isFile) {
                    throw GradleException(
                        "[RELEASE SIGNING CONFIG ERROR] Keystore file not found at: ${resolvedFile?.absolutePath ?: storeFileProp}\n" +
                        "Please verify 'storeFile' in ${keystorePropertiesFile.absolutePath}"
                    )
                }

                keyAlias = keyAliasVal
                keyPassword = keyPasswordVal
                storeFile = resolvedFile
                storePassword = storePasswordVal
            }
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
        release {
            // Production release builds must NEVER silently fall back to debug signing.
            // Signing with official release signingConfig is strictly enforced.
            signingConfig = signingConfigs.getByName("release")
        }
    }

    flavorDimensions.add("default")

    productFlavors {
        create("dev") {
            dimension = "default"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Tactile Dev")
            // Development builds use the debug signing configuration so testing is uninterrupted
            signingConfig = signingConfigs.getByName("debug")
        }
        create("prod") {
            dimension = "default"
            resValue("string", "app_name", "The Tactile Archive")
            // Production flavor inherits signingConfig from buildTypes (release -> signingConfigs.release)
        }
    }
}

// ---------------------------------------------------------------------------
// Standalone Safe Configuration Validation Task (Requirement 7)
// ---------------------------------------------------------------------------
tasks.register("validateProductionSigning") {
    group = "verification"
    description = "Validates that official release signing credentials and keystore are present for production builds."
    doFirst {
        if (!hasKeystoreProperties) {
            throw GradleException(
                "\n" +
                "========================================================================================\n" +
                "[PRODUCTION RELEASE SIGNING FAILURE — FAIL-FAST GATE ENFORCED]\n" +
                "A production release build was requested, but valid signing configuration is missing!\n" +
                "Missing file: ${keystorePropertiesFile.absolutePath}\n" +
                "\n" +
                "Production release builds must NEVER silently fall back to debug signing.\n" +
                "To resolve this, provision '${keystorePropertiesFile.name}' with:\n" +
                "  keyAlias=<your-alias>\n" +
                "  keyPassword=<your-key-password>\n" +
                "  storeFile=<path-to-upload-keystore.jks>\n" +
                "  storePassword=<your-store-password>\n" +
                "========================================================================================\n"
            )
        }

        val keyAliasVal = keystoreProperties.getProperty("keyAlias")
        val keyPasswordVal = keystoreProperties.getProperty("keyPassword")
        val storePasswordVal = keystoreProperties.getProperty("storePassword")
        val storeFileProp = keystoreProperties.getProperty("storeFile")

        if (keyAliasVal.isNullOrBlank()) {
            throw GradleException("[PRODUCTION RELEASE SIGNING FAILURE] 'keyAlias' property is missing or empty in ${keystorePropertiesFile.name}")
        }
        if (keyPasswordVal.isNullOrBlank()) {
            throw GradleException("[PRODUCTION RELEASE SIGNING FAILURE] 'keyPassword' property is missing or empty in ${keystorePropertiesFile.name}")
        }
        if (storePasswordVal.isNullOrBlank()) {
            throw GradleException("[PRODUCTION RELEASE SIGNING FAILURE] 'storePassword' property is missing or empty in ${keystorePropertiesFile.name}")
        }
        if (storeFileProp.isNullOrBlank()) {
            throw GradleException("[PRODUCTION RELEASE SIGNING FAILURE] 'storeFile' property is missing or empty in ${keystorePropertiesFile.name}")
        }

        val resolvedFile = resolveKeystoreFile(storeFileProp)
        if (resolvedFile == null || !resolvedFile.exists() || !resolvedFile.isFile) {
            throw GradleException(
                "[PRODUCTION RELEASE SIGNING FAILURE] Configured keystore file does not exist: ${resolvedFile?.absolutePath ?: storeFileProp}\n" +
                "Please verify 'storeFile' in ${keystorePropertiesFile.name}"
            )
        }

        println("[PRODUCTION RELEASE SIGNING] Configuration verified successfully.")
        println("  Keystore: ${resolvedFile.absolutePath}")
        println("  Key Alias: $keyAliasVal")
    }
}

// Wire validation task to execute before production release assembly/bundling
tasks.matching { task ->
    val name = task.name.lowercase()
    name.contains("prod") && (name.contains("release") || name.contains("bundle")) && !name.contains("debug")
}.configureEach {
    dependsOn("validateProductionSigning")
}

flutter {
    source = "../.."
}
