package com.frog.playstream

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.frog.playstream.extensions.ExtensionBridge

class MainActivity : FlutterActivity() {
    private val URL_LAUNCHER_CHANNEL = "com.playstream/url_launcher"
    private val EXTENSIONS_CHANNEL = "com.playstream/extensions"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // URL Launcher channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, URL_LAUNCHER_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUrl") {
                val url = call.argument<String>("url")
                if (url != null) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_ERROR", "Failed to launch URL: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_URL", "URL is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        // Extensions channel
        val extensionBridge = ExtensionBridge(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXTENSIONS_CHANNEL)
            .setMethodCallHandler(extensionBridge)
    }
}
