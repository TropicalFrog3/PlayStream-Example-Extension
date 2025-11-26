package com.frog.playstream.extensions

import android.webkit.JavascriptInterface
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Native HTTP client that is injected into the JavaScript runtime.
 * Provides HTTP GET and POST methods that can be called from JavaScript extensions.
 * 
 * Methods are annotated with @JavascriptInterface to be accessible from the JS context.
 */
class NativeHttpClient {
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .followRedirects(true)
        .followSslRedirects(true)
        .build()
    
    /**
     * Performs an HTTP GET request.
     * 
     * @param url The URL to request
     * @param headersJson JSON string containing headers as key-value pairs (optional)
     * @return The response body as a string
     * @throws IOException if the request fails
     */
    @JavascriptInterface
    fun get(url: String, headersJson: String = "{}"): String {
        return executeRequest(url, "GET", headersJson, null)
    }
    
    /**
     * Performs an HTTP POST request.
     * 
     * @param url The URL to request
     * @param body The request body as a string
     * @param headersJson JSON string containing headers as key-value pairs (optional)
     * @return The response body as a string
     * @throws IOException if the request fails
     */
    @JavascriptInterface
    fun post(url: String, body: String, headersJson: String = "{}"): String {
        return executeRequest(url, "POST", headersJson, body)
    }
    
    /**
     * Internal method to execute HTTP requests.
     * 
     * @param url The URL to request
     * @param method The HTTP method (GET or POST)
     * @param headersJson JSON string containing headers
     * @param body Optional request body for POST requests
     * @return The response body as a string
     * @throws IOException if the request fails
     */
    private fun executeRequest(
        url: String,
        method: String,
        headersJson: String,
        body: String?
    ): String {
        try {
            // Parse headers from JSON
            val headers = parseHeaders(headersJson)
            
            // Build the request
            val requestBuilder = Request.Builder().url(url)
            
            // Add headers
            headers.forEach { (key, value) ->
                requestBuilder.addHeader(key, value)
            }
            
            // Add body for POST requests
            if (method == "POST" && body != null) {
                val contentType = headers["Content-Type"] ?: "application/json"
                val requestBody = body.toRequestBody(contentType.toMediaType())
                requestBuilder.post(requestBody)
            }
            
            val request = requestBuilder.build()
            
            // Execute the request
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("HTTP ${response.code}: ${response.message}")
                }
                
                return response.body?.string() ?: ""
            }
            
        } catch (e: Exception) {
            // Wrap exceptions in a format that JS can handle
            throw IOException("Network request failed: ${e.message}", e)
        }
    }
    
    /**
     * Parses a JSON string into a map of headers.
     * 
     * @param headersJson JSON string containing headers
     * @return Map of header key-value pairs
     */
    private fun parseHeaders(headersJson: String): Map<String, String> {
        return try {
            val headers = mutableMapOf<String, String>()
            val jsonObject = JSONObject(headersJson)
            
            jsonObject.keys().forEach { key ->
                headers[key] = jsonObject.getString(key)
            }
            
            headers
        } catch (e: Exception) {
            // If parsing fails, return empty map
            emptyMap()
        }
    }
}
