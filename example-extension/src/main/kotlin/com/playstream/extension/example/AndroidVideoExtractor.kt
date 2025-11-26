package com.playstream.extension.example

import android.webkit.WebView
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebViewClient
import android.os.Handler
import android.os.Looper
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * Android WebView-based video URL extractor.
 * This extracts video URLs by intercepting network requests in a WebView.
 * 
 * Note: This requires Android context and must be run on the main thread.
 */
class AndroidVideoExtractor(private val context: android.content.Context) {
    
    private var webView: WebView? = null
    
    /**
     * Extract video URL from an embed page using WebView.
     * 
     * @param embedUrl The embed URL to load
     * @param timeout Maximum time to wait in milliseconds
     * @return The extracted video.m3u8 URL or null if not found
     */
    fun extractVideoUrl(embedUrl: String, timeout: Long = 15000): String? {
        val videoUrlRef = AtomicReference<String?>()
        val latch = CountDownLatch(1)
        
        // Must run on main thread
        Handler(Looper.getMainLooper()).post {
            try {
                webView = WebView(context).apply {
                    settings.apply {
                        javaScriptEnabled = true
                        domStorageEnabled = true
                        userAgentString = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
                    }
                    
                    webViewClient = object : WebViewClient() {
                        override fun shouldInterceptRequest(
                            view: WebView?,
                            request: WebResourceRequest?
                        ): WebResourceResponse? {
                            val url = request?.url?.toString() ?: return null
                            
                            // Check if this is the video.m3u8 URL we're looking for
                            if (url.contains("video.m3u8") && url.contains("?q=")) {
                                println("✓ Captured video URL: $url")
                                videoUrlRef.set(url)
                                latch.countDown()
                            }
                            
                            return null // Continue normal loading
                        }
                        
                        override fun onPageFinished(view: WebView?, url: String?) {
                            super.onPageFinished(view, url)
                            // Give JavaScript time to execute
                            Handler(Looper.getMainLooper()).postDelayed({
                                if (latch.count > 0) {
                                    println("⚠ Page loaded but video URL not found")
                                    latch.countDown()
                                }
                            }, 5000)
                        }
                    }
                    
                    loadUrl(embedUrl)
                }
            } catch (e: Exception) {
                println("✗ Error creating WebView: ${e.message}")
                latch.countDown()
            }
        }
        
        // Wait for the video URL to be captured or timeout
        val captured = latch.await(timeout, TimeUnit.MILLISECONDS)
        
        // Cleanup
        Handler(Looper.getMainLooper()).post {
            webView?.destroy()
            webView = null
        }
        
        if (!captured) {
            println("⚠ Timeout waiting for video URL")
        }
        
        return videoUrlRef.get()
    }
}
