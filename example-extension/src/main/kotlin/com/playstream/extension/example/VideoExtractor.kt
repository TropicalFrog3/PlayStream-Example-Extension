package com.playstream.extension.example

import com.microsoft.playwright.*
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Headless browser-based video URL extractor using Playwright.
 * This extracts video URLs by intercepting network requests.
 * 
 * Note: This uses Playwright which is JVM-only. For Android runtime,
 * you'll need to use WebView or a different approach.
 */
class VideoExtractor {
    
    private var playwright: Playwright? = null
    private var browser: Browser? = null
    
    /**
     * Initialize Playwright and browser instance.
     * Call this once at startup.
     */
    fun initialize() {
        if (playwright == null) {
            try {
                playwright = Playwright.create()
                browser = playwright!!.chromium().launch(
                    BrowserType.LaunchOptions()
                        .setHeadless(true)
                        .setArgs(listOf(
                            "--disable-gpu",
                            "--no-sandbox",
                            "--disable-dev-shm-usage"
                        ))
                )
                println("✓ Playwright initialized successfully")
            } catch (e: Exception) {
                println("✗ Failed to initialize Playwright: ${e.message}")
                println("  Make sure Playwright browsers are installed:")
                println("  Run: mvn exec:java -e -D exec.mainClass=com.microsoft.playwright.CLI -D exec.args=\"install\"")
            }
        }
    }
    
    /**
     * Extract video URL from an embed page.
     * 
     * @param embedUrl The embed URL to load
     * @param timeout Maximum time to wait in milliseconds
     * @return The extracted video.m3u8 URL or null if not found
     */
    fun extractVideoUrl(embedUrl: String, timeout: Long = 15000): String? {
        initialize()
        
        if (browser == null) {
            println("✗ Browser not initialized")
            return null
        }
        
        val videoUrlRef = AtomicReference<String?>()
        val latch = CountDownLatch(1)
        
        val context = browser!!.newContext(
            Browser.NewContextOptions()
                .setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        )
        
        val page = context.newPage()
        
        try {
            // Intercept network requests to capture video URL
            page.route("**/*") { route ->
                val url = route.request().url()
                
                // Check if this is the video.m3u8 URL we're looking for
                if (url.contains("video.m3u8") && url.contains("?q=")) {
                    println("✓ Captured video URL: $url")
                    videoUrlRef.set(url)
                    latch.countDown()
                }
                
                // Continue the request
                route.resume()
            }
            
            // Navigate to the embed page
            println("Loading embed page: $embedUrl")
            page.navigate(embedUrl, Page.NavigateOptions().setTimeout(timeout.toDouble()))
            
            // Wait for the video URL to be captured or timeout
            val captured = latch.await(timeout, TimeUnit.MILLISECONDS)
            
            if (!captured) {
                println("⚠ Timeout waiting for video URL")
            }
            
            return videoUrlRef.get()
            
        } catch (e: Exception) {
            println("✗ Error extracting video URL: ${e.message}")
            e.printStackTrace()
            return null
        } finally {
            page.close()
            context.close()
        }
    }
    
    /**
     * Close the browser and Playwright instance.
     * Call this when shutting down.
     */
    fun close() {
        browser?.close()
        playwright?.close()
        browser = null
        playwright = null
    }
}
