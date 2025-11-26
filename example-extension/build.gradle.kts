plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.playstream.extension.example"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.playstream.extension.example"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
    
    lint {
        disable += "NewApi"
        abortOnError = false
    }
    
    testOptions {
        unitTests.all {
            it.useJUnitPlatform()
        }
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("org.yaml:snakeyaml:2.2")
    implementation("org.jsoup:jsoup:1.17.2")
    
    // Playwright for headless browser (JVM only - for testing)
    implementation("com.microsoft.playwright:playwright:1.40.0")
    
    testImplementation("io.kotest:kotest-runner-junit5:5.8.0")
    testImplementation("io.kotest:kotest-assertions-core:5.8.0")
    testImplementation("io.kotest:kotest-property:5.8.0")
    testImplementation("junit:junit:4.13.2")
}

tasks.register<JavaExec>("runMain") {
    group = "application"
    description = "Run the simple Main.kt test"
    
    classpath = files(
        "${layout.buildDirectory.get()}/intermediates/javac/debug/classes",
        "${layout.buildDirectory.get()}/tmp/kotlin-classes/debug"
    ) + configurations.getByName("debugRuntimeClasspath")
    
    mainClass.set("com.playstream.extension.example.MainKt")
    
    dependsOn("compileDebugKotlin", "compileDebugJavaWithJavac")
}
