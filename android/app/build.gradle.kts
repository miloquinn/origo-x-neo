import com.android.build.api.dsl.ApplicationExtension
import java.util.Base64
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val releaseKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")
val releaseKeystoreType = if (releaseKeystorePath?.endsWith(".p12", ignoreCase = true) == true ||
    releaseKeystorePath?.endsWith(".pfx", ignoreCase = true) == true
) {
    "PKCS12"
} else {
    "JKS"
}
val hasReleaseSigning = listOf(
    releaseKeystorePath,
    releaseKeystorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
).all { !it.isNullOrBlank() }

fun decodedDartDefines(): Map<String, String> =
    providers.gradleProperty("dart-defines").orNull
        ?.split(',')
        ?.mapNotNull { encoded ->
            runCatching {
                String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull()
        }
        ?.mapNotNull { definition ->
            val separator = definition.indexOf('=')
            if (separator <= 0) null else definition.substring(0, separator) to
                definition.substring(separator + 1)
        }
        ?.toMap()
        .orEmpty()

val distributionChannel =
    decodedDartDefines()["ORIGO_DISTRIBUTION_CHANNEL"] ?: "direct"
if (distributionChannel !in setOf("direct", "googlePlay")) {
    throw GradleException(
        "Android ORIGO_DISTRIBUTION_CHANNEL must be direct or googlePlay, got $distributionChannel.",
    )
}

val sourceManifest = file("src/main/AndroidManifest.xml")
val generatedDistributionManifest = layout.buildDirectory.file(
    "generated/origoDistributionManifest/AndroidManifest.xml",
)
val generateDistributionManifest by tasks.registering {
    group = "build setup"
    description = "Generates the Android manifest for the selected distribution channel."
    inputs.file(sourceManifest)
    inputs.property("distributionChannel", distributionChannel)
    outputs.file(generatedDistributionManifest)
    doLast {
        val marker = "    <!-- ORIGO_DISTRIBUTION_PERMISSION -->"
        val source = sourceManifest.readText()
        if (!source.contains(marker)) {
            throw GradleException("Distribution permission marker is missing from $sourceManifest")
        }
        val permission = if (distributionChannel == "googlePlay") {
            """    <uses-permission
        android:name="android.permission.REQUEST_INSTALL_PACKAGES"
        tools:node="remove" />"""
        } else {
            """    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />"""
        }
        val output = generatedDistributionManifest.get().asFile
        output.parentFile.mkdirs()
        output.writeText(source.replace(marker, "$marker\n$permission"))
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any {
        it.name.contains("release", ignoreCase = true) &&
            (it.name.contains("assemble", ignoreCase = true) ||
                it.name.contains("bundle", ignoreCase = true) ||
                it.name.contains("package", ignoreCase = true))
    }
    if (buildsRelease && !hasReleaseSigning) {
        throw GradleException(
            "Release signing is required. Set ANDROID_KEYSTORE_PATH, " +
                "ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, and ANDROID_KEY_PASSWORD.",
        )
    }
}

extensions.configure<ApplicationExtension> {
    namespace = "com.niki.xxread"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        buildConfig = true
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.niki.xxread"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_release_build_number", flutter.versionCode.toString())
    }

    sourceSets.getByName("main").manifest.srcFile(
        generatedDistributionManifest.get().asFile,
    )

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseKeystorePath!!)
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                storeType = releaseKeystoreType
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        debug {
            // 临时：本机验证时用发布签名覆盖安装正式版，避免签名不一致被拒装
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
        getByName("profile") {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

tasks.matching {
    it.name.startsWith("process") && it.name.endsWith("MainManifest")
}.configureEach {
    dependsOn(generateDistributionManifest)
}

val verifyReleaseDistributionManifest by tasks.registering {
    group = "verification"
    description = "Checks channel-specific Android package-install permission."
    dependsOn("processReleaseMainManifest")
    doLast {
        val mergedManifest = layout.buildDirectory.file(
            "intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml",
        ).get().asFile
        if (!mergedManifest.isFile) {
            throw GradleException("Merged release manifest is missing: $mergedManifest")
        }
        val hasInstallPermission = mergedManifest.readText().contains(
            "android.permission.REQUEST_INSTALL_PACKAGES",
        )
        if (distributionChannel == "googlePlay" && hasInstallPermission) {
            throw GradleException(
                "Google Play builds must not request REQUEST_INSTALL_PACKAGES.",
            )
        }
        if (distributionChannel == "direct" && !hasInstallPermission) {
            throw GradleException(
                "Direct-download builds must retain REQUEST_INSTALL_PACKAGES.",
            )
        }
    }
}

tasks.matching {
    it.name == "bundleRelease" || it.name == "assembleRelease"
}.configureEach {
    dependsOn(verifyReleaseDistributionManifest)
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")

}

flutter {
    source = "../.."
}
