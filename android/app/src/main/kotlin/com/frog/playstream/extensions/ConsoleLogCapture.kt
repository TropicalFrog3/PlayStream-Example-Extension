package com.frog.playstream.extensions

import android.util.Log
import java.io.ByteArrayOutputStream
import java.io.PrintStream

/**
 * Captures console output (System.out and System.err) during extension execution.
 * This allows us to capture println() and other console output from extensions.
 */
class ConsoleLogCapture {
    
    data class LogEntry(
        val level: String,
        val message: String,
        val timestamp: Long
    )
    
    private val logs = mutableListOf<LogEntry>()
    private val originalOut = System.out
    private val originalErr = System.err
    private var isCapturing = false
    
    /**
     * Start capturing console output
     */
    fun startCapture() {
        if (isCapturing) return
        
        isCapturing = true
        logs.clear()
        
        // Capture System.out (info/debug logs)
        System.setOut(PrintStream(object : ByteArrayOutputStream() {
            override fun flush() {
                val output = toString().trim()
                if (output.isNotEmpty()) {
                    captureLog("info", output)
                    reset()
                }
            }
            
            override fun write(b: ByteArray, off: Int, len: Int) {
                super.write(b, off, len)
                val output = String(b, off, len).trim()
                if (output.isNotEmpty() && output != "\n" && output != "\r\n") {
                    captureLog("info", output)
                }
            }
        }))
        
        // Capture System.err (error logs)
        System.setErr(PrintStream(object : ByteArrayOutputStream() {
            override fun flush() {
                val output = toString().trim()
                if (output.isNotEmpty()) {
                    captureLog("error", output)
                    reset()
                }
            }
            
            override fun write(b: ByteArray, off: Int, len: Int) {
                super.write(b, off, len)
                val output = String(b, off, len).trim()
                if (output.isNotEmpty() && output != "\n" && output != "\r\n") {
                    captureLog("error", output)
                }
            }
        }))
    }
    
    /**
     * Stop capturing and restore original streams
     */
    fun stopCapture() {
        if (!isCapturing) return
        
        System.setOut(originalOut)
        System.setErr(originalErr)
        isCapturing = false
    }
    
    /**
     * Capture a log entry with level detection
     */
    private fun captureLog(defaultLevel: String, message: String) {
        val level = detectLogLevel(message, defaultLevel)
        val entry = LogEntry(
            level = level,
            message = message,
            timestamp = System.currentTimeMillis()
        )
        logs.add(entry)
        
        // Also log to Android logcat for debugging
        when (level) {
            "debug" -> Log.d("ExtensionLog", message)
            "info" -> Log.i("ExtensionLog", message)
            "warn" -> Log.w("ExtensionLog", message)
            "error" -> Log.e("ExtensionLog", message)
        }
    }
    
    /**
     * Detect log level from message content
     */
    private fun detectLogLevel(message: String, defaultLevel: String): String {
        val lowerMessage = message.lowercase()
        return when {
            lowerMessage.contains("[dbg]") || lowerMessage.contains("debug:") -> "debug"
            lowerMessage.contains("[info]") || lowerMessage.contains("info:") -> "info"
            lowerMessage.contains("[warn]") || lowerMessage.contains("warning:") -> "warn"
            lowerMessage.contains("[err]") || lowerMessage.contains("error:") -> "error"
            lowerMessage.startsWith("error") || lowerMessage.contains("exception") -> "error"
            lowerMessage.startsWith("warn") -> "warn"
            else -> defaultLevel
        }
    }
    
    /**
     * Get all captured logs
     */
    fun getLogs(): List<LogEntry> = logs.toList()
    
    /**
     * Convert logs to map format for Flutter
     */
    fun getLogsAsMap(): List<Map<String, Any>> {
        return logs.map { entry ->
            mapOf(
                "level" to entry.level,
                "message" to entry.message,
                "timestamp" to entry.timestamp
            )
        }
    }
    
    /**
     * Clear all captured logs
     */
    fun clear() {
        logs.clear()
    }
}
