# Android Usage Guide

## Setting Up the Extension on Android

The extension now supports Android through WebView-based video extraction. Here's how to use it:

### 1. Initialize the Provider

```kotlin
val provider = ExampleProvider()

// IMPORTANT: Set Android context before using
provider.setAndroidContext(context) // or applicationContext
```

### 2. Search for Media

```kotlin
val searchOptions = SearchOptions(
    media = Media(
        id = 0,
        format = "TV",
        englishTitle = "Wednesday",
        episodeCount = 8,
        synonyms = emptyList(),
        isAdult = false,
        tmdbId = "119051"
    ),
    query = "Wednesday",
    dub = true
)

val results = provider.searchMedia(searchOptions)
```

### 3. Get Episodes

```kotlin
val episodes = provider.getEpisodes(results.first().id)
```

### 4. Extract Video URL

```kotlin
// This will use Android WebView automatically
val server = provider.getEpisodeServer(episodes.first(), "server1")

if (server.videoSources.isNotEmpty()) {
    val videoUrl = server.videoSources.first().url
    println("Video URL: $videoUrl")
    
    // Use the URL with your video player
    playVideo(videoUrl, server.headers)
}
```

## How It Works

### Platform Detection

The extension automatically detects whether it's running on Android or JVM:

- **Android**: Uses `WebView` to load the embed page and intercept network requests
- **JVM/Desktop**: Uses `Playwright` with headless Chromium

### WebView Extraction Process

1. Creates a hidden WebView with JavaScript enabled
2. Loads the embed URL
3. Intercepts all network requests via `WebViewClient.shouldInterceptRequest()`
4. Captures the `video.m3u8?q=...` URL when detected
5. Returns the URL and destroys the WebView

### Threading

The WebView operations run on the Android main thread (UI thread) as required by Android. The extraction method blocks until:
- The video URL is captured, or
- A timeout occurs (default 15 seconds)

## Example Integration

### In an Activity

```kotlin
class VideoPlayerActivity : AppCompatActivity() {
    
    private val provider = ExampleProvider()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set context
        provider.setAndroidContext(this)
        
        // Extract video in background
        lifecycleScope.launch(Dispatchers.IO) {
            val server = provider.getEpisodeServer(episode, "server1")
            
            withContext(Dispatchers.Main) {
                if (server.videoSources.isNotEmpty()) {
                    playVideo(server.videoSources.first().url)
                }
            }
        }
    }
}
```

### In a Service

```kotlin
class ExtensionService : Service() {
    
    private val provider = ExampleProvider()
    
    override fun onCreate() {
        super.onCreate()
        provider.setAndroidContext(applicationContext)
    }
    
    fun extractVideo(episodeUrl: String): String? {
        val episode = EpisodeDetails(
            id = episodeUrl,
            number = 1,
            url = episodeUrl,
            title = "Episode"
        )
        
        val server = provider.getEpisodeServer(episode, "server1")
        return server.videoSources.firstOrNull()?.url
    }
}
```

## Performance Considerations

### Extraction Time
- Takes 5-15 seconds per episode
- Depends on network speed and page load time
- WebView must wait for JavaScript to execute

### Memory Usage
- WebView is created and destroyed for each extraction
- Minimal memory footprint when not in use
- No persistent browser process

### Optimization Tips

1. **Cache Results**: Store extracted URLs to avoid re-extraction
2. **Background Thread**: Always run extraction on a background thread
3. **Timeout**: Adjust timeout based on network conditions
4. **Batch Processing**: Extract multiple episodes sequentially, not in parallel

## Troubleshooting

### "Android context not set" Error

```kotlin
// Make sure to call this before using the provider
provider.setAndroidContext(context)
```

### WebView Not Loading

Check these permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Timeout Issues

Increase the timeout if needed:

```kotlin
// In AndroidVideoExtractor.kt, modify the timeout parameter
val videoUrl = androidExtractor.extractVideoUrl(episode.url, timeout = 30000) // 30 seconds
```

### Video URL Not Captured

The site might have changed its structure. Check:
1. The embed URL format is correct
2. The site is accessible
3. JavaScript is enabled in WebView
4. Network interception is working

## Security Notes

- WebView runs with JavaScript enabled (required for extraction)
- Only intercepts network requests, doesn't modify them
- No data is stored or transmitted
- WebView is destroyed after each use

## Limitations

- Requires Android API 21+ (Android 5.0)
- Must run on main thread for WebView operations
- Cannot run multiple extractions simultaneously
- Slower than direct API calls (due to page loading)

## Alternative Approaches

If WebView extraction is too slow or unreliable, consider:

1. **Reverse Engineering**: Analyze the WASM module to decrypt API responses directly
2. **Proxy Server**: Run Playwright on a server and call it from the app
3. **Native Decryption**: Implement the decryption algorithm in Kotlin

## Support

For issues or questions about Android usage, please open an issue on GitHub with:
- Android version
- Device model
- Error logs
- Steps to reproduce
