# Template Extension

A minimal template for creating PlayStream extensions.

## Getting Started

1. Copy this template folder and rename it to your extension name
2. Update the following files with your extension details:
   - `manifest.json` - Extension metadata
   - `build.gradle.kts` - Package name and dependencies
   - `settings.gradle.kts` - Project name
   - `src/main/AndroidManifest.xml` - Package and provider class
   - `src/main/kotlin/com/playstream/extension/template/TemplateProvider.kt` - Implementation

3. Implement the required methods:
   - `searchMedia()` - Search for media content
   - `getEpisodes()` - Get episodes for a media item
   - `getEpisodeServer()` - Extract video sources
   - `getProviderSettings()` - Configure extension settings

## Building

Run the build script for your platform:
- Windows: `gradlew.bat assembleRelease`
- Linux/Mac: `./gradlew assembleRelease`

The APK will be generated in `build/outputs/apk/release/`
