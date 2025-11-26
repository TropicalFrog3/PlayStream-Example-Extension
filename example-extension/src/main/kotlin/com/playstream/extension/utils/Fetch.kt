package com.playstream.extension.utils

import java.net.HttpURLConnection
import java.net.URL
import org.jsoup.Jsoup
import org.jsoup.nodes.Document

/**
 * HTTP fetch utility for making web requests.
 */
object Fetch {
    
    private const val DEFAULT_USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    private const val DEFAULT_TIMEOUT = 10000
    
    /**
     * Fetch HTML content from a URL.
     */
    fun html(
        url: String,
        method: String = "GET",
        headers: Map<String, String> = emptyMap(),
        body: String? = null,
        timeout: Int = DEFAULT_TIMEOUT
    ): String {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.requestMethod = method
        connection.setRequestProperty("User-Agent", DEFAULT_USER_AGENT)
        connection.setRequestProperty("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
        connection.connectTimeout = timeout
        connection.readTimeout = timeout
        
        headers.forEach { (key, value) ->
            connection.setRequestProperty(key, value)
        }
        
        if (body != null && (method == "POST" || method == "PUT")) {
            connection.doOutput = true
            connection.outputStream.bufferedWriter().use { it.write(body) }
        }
        
        return try {
            connection.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            println("Error fetching $url: ${e.message}")
            ""
        } finally {
            connection.disconnect()
        }
    }
    
    /**
     * Fetch and parse HTML as a Jsoup Document.
     */
    fun document(
        url: String,
        method: String = "GET",
        headers: Map<String, String> = emptyMap(),
        body: String? = null
    ): Document {
        val htmlContent = html(url, method, headers, body)
        return Jsoup.parse(htmlContent)
    }
    
    /**
     * Fetch JSON content from a URL.
     */
    fun json(
        url: String,
        method: String = "GET",
        headers: Map<String, String> = emptyMap(),
        body: String? = null
    ): String {
        val allHeaders = headers.toMutableMap()
        allHeaders["Accept"] = "application/json"
        if (body != null) {
            allHeaders["Content-Type"] = "application/json"
        }
        return html(url, method, allHeaders, body)
    }
    
    /**
     * URL encode a string.
     */
    fun encode(value: String): String = java.net.URLEncoder.encode(value, "UTF-8")
}
