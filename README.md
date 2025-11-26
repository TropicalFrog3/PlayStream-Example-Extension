# PlayStream Example Extension

An example extension for PlayStream that demonstrates video extraction using headless browser automation.

## Features

- 🎬 Extracts video URLs from encrypted streaming sources
- 🤖 Uses Playwright for headless browser automation
- 📺 Supports TV shows with multiple episodes
- 🔍 Automatic video source detection via network interception

## How It Works

This extension uses Playwright (headless Chromium) to:
1. Load the embed page in a headless browser
2. Intercept network requests
3. Capture the encrypted video.m3u8 URL
4. Return it as a playable video source

## Installation

### Download APK
Download the latest APK from the releases:
- [example-extension-v1.0.0.apk](build/example-extension/outputs/apk/example-extension-v1.0.0.apk)

### Build from Source

```bash
cd example-extension
./gradlew assembleRelease
```

The APK will be generated at:
```
example-extension/build/outputs/apk/release/example-extension-release-unsigned.apk
```

## Testing (Desktop/JVM Only)

To test the extension on desktop:

```bash
cd example-extension
./gradlew runMain
```

**Note:** Playwright requires JVM and will automatically download Chromium (~100MB) on first run.

## Important Notes

⚠️ **Android Limitation**: Playwright does NOT work on Android devices. The current implementation is for testing purposes only. For production Android use, you'll need to:

1. Use Android WebView to load and intercept requests
2. Set up a proxy server running Playwright
3. Reverse engineer the encryption algorithm

## Project Structure

```
example-extension/
├── src/main/kotlin/com/playstream/extension/example/
│   ├── ExampleProvider.kt      # Main provider implementation
│   ├── VideoExtractor.kt       # Playwright-based video URL extractor
│   └── Main.kt                 # Test runner
├── build.gradle.kts            # Build configuration
└── manifest.json               # Extension manifest
```

## Dependencies

- Kotlin 1.9.0
- Playwright 1.40.0 (JVM only)
- Jsoup 1.17.2
- Gson 2.10.1

## Configuration

The extension targets:
- **Base URL**: `https://www.vidking.net`
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)

## Development

### Adding New Features

1. Modify `ExampleProvider.kt` to add new functionality
2. Update `VideoExtractor.kt` for different extraction methods
3. Test using `./gradlew runMain`
4. Build APK with `./gradlew assembleRelease`

### Debugging

Enable verbose logging in `VideoExtractor.kt` to see:
- Browser initialization status
- Network request interception
- Video URL capture events

## License

This is an example extension for educational purposes.

## Contributing

Feel free to fork and modify this extension for your own use cases!

## Support

For issues or questions, please open an issue on GitHub.
