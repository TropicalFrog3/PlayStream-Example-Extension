# Release v1.0.0 - PlayStream Example Extension

## 🎉 Initial Release

This is the first release of the PlayStream Example Extension, demonstrating advanced video extraction using headless browser automation.

## ✨ Features

- **Headless Browser Extraction**: Uses Playwright to extract encrypted video URLs
- **Network Interception**: Automatically captures video.m3u8 URLs from network requests
- **Multi-Episode Support**: Handles TV shows with multiple episodes
- **Encrypted Source Support**: Works with encrypted streaming sources that use client-side decryption

## 📦 Installation

### Option 1: Download APK
Download the APK from this release:
- `example-extension-v1.0.0.apk`

### Option 2: Build from Source
```bash
cd example-extension
./gradlew assembleRelease
```

## 🧪 Testing (Desktop/JVM Only)

To test the extension on desktop:

```bash
cd example-extension
./gradlew runMain
```

**Note**: Playwright will automatically download Chromium (~100MB) on first run.

## ⚠️ Important Limitations

### Android Runtime
**Playwright does NOT work on Android devices.** This implementation is primarily for:
- Desktop testing and development
- Understanding the video extraction flow
- Demonstration purposes

### For Production Android Use
You'll need to implement one of these alternatives:
1. **Android WebView** - Load embed URLs in WebView and intercept requests
2. **Proxy Server** - Run Playwright on a server and call it from the app
3. **Direct Decryption** - Reverse engineer the WASM module to decrypt API responses

## 🏗️ Technical Details

### Architecture
- **Language**: Kotlin
- **Build System**: Gradle
- **Browser Automation**: Playwright 1.40.0
- **HTML Parsing**: Jsoup 1.17.2

### How It Works
1. Loads the embed page in headless Chromium
2. Intercepts all network requests
3. Captures requests to `video.m3u8?q=...`
4. Returns the encrypted video URL

### Target Site
- Base URL: `https://www.vidking.net`
- Format: `/embed/{TYPE}/{TMDB_ID}/{SEASON}/{EPISODE}`

## 📝 Example Usage

```kotlin
val provider = ExampleProvider()

// Search for media
val results = provider.searchMedia(searchOptions)

// Get episodes
val episodes = provider.getEpisodes(results.first().id)

// Get video source
val server = provider.getEpisodeServer(episodes.first(), "server1")
val videoUrl = server.videoSources.first().url
```

## 🐛 Known Issues

1. **Slow Extraction**: Takes 5-15 seconds per episode due to browser loading
2. **Android Incompatibility**: Playwright requires full JVM, not available on Android
3. **Resource Intensive**: Chromium uses significant memory and CPU

## 🔮 Future Improvements

- [ ] Implement Android WebView alternative
- [ ] Add caching for extracted URLs
- [ ] Support for multiple video sources
- [ ] Subtitle extraction
- [ ] Quality selection

## 📄 License

This is an example extension for educational purposes.

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Fork for your own use cases

## 📧 Support

For issues or questions, please open an issue on GitHub.

---

**Version**: 1.0.0  
**Release Date**: November 26, 2025  
**Minimum Android**: 5.0 (API 21)  
**Target Android**: 14 (API 34)
