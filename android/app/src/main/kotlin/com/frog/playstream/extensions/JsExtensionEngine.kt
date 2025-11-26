package com.frog.playstream.extensions

import android.util.Log
import app.cash.quickjs.QuickJs
import org.json.JSONArray
import org.json.JSONObject

/**
 * JavaScript Extension Engine that manages the QuickJS runtime.
 * Provides methods to load JavaScript code and execute functions within the JS context.
 * 
 * This engine is responsible for:
 * - Loading and initializing JavaScript extension code
 * - Executing JavaScript functions with parameters
 * - Handling errors and exceptions from the JS runtime
 * - Properly managing the QuickJS context lifecycle
 */
class JsExtensionEngine(private val context: android.content.Context? = null) {
    
    private var quickJs: QuickJs? = null
    private var isInitialized = false
    private val nativeHttpClient = NativeHttpClient()
    private val consoleLogs = mutableListOf<String>()
    
    companion object {
        private const val TAG = "JsExtensionEngine"
    }
    
    /**
     * Loads and initializes a JavaScript extension script.
     * 
     * This method:
     * 1. Creates a new QuickJS context
     * 2. Injects the native HTTP client bridge
     * 3. Evaluates the provided JavaScript code
     * 
     * @param script The JavaScript code to load and execute
     * @throws IllegalStateException if the engine is already initialized
     * @throws RuntimeException if script loading or evaluation fails
     */
    fun loadScript(script: String) {
        if (isInitialized) {
            throw IllegalStateException("Engine is already initialized. Call close() before loading a new script.")
        }
        
        try {
            Log.d(TAG, "Initializing QuickJS context...")
            quickJs = QuickJs.create()
            
            // Add console.log support and Promise handling for async functions
            Log.d(TAG, "Setting up JavaScript environment...")
            quickJs?.evaluate("""
                var __consoleLogs = [];
                var console = {
                    log: function() {
                        var args = Array.prototype.slice.call(arguments);
                        var message = args.map(function(arg) {
                            return typeof arg === 'object' ? JSON.stringify(arg) : String(arg);
                        }).join(' ');
                        __consoleLogs.push({type: 'log', message: message});
                        return message;
                    },
                    error: function() {
                        var args = Array.prototype.slice.call(arguments);
                        var message = args.map(function(arg) {
                            return typeof arg === 'object' ? JSON.stringify(arg) : String(arg);
                        }).join(' ');
                        __consoleLogs.push({type: 'error', message: message});
                        return message;
                    },
                    warn: function() {
                        var args = Array.prototype.slice.call(arguments);
                        var message = args.map(function(arg) {
                            return typeof arg === 'object' ? JSON.stringify(arg) : String(arg);
                        }).join(' ');
                        __consoleLogs.push({type: 'warn', message: message});
                        return message;
                    },
                    info: function() {
                        var args = Array.prototype.slice.call(arguments);
                        var message = args.map(function(arg) {
                            return typeof arg === 'object' ? JSON.stringify(arg) : String(arg);
                        }).join(' ');
                        __consoleLogs.push({type: 'info', message: message});
                        return message;
                    }
                };
                
                // Global state for promise resolution
                var __promiseState = {
                    resolved: false,
                    result: null,
                    error: null
                };
            """.trimIndent())
            
            Log.d(TAG, "Evaluating extension script...")
            quickJs?.evaluate(script)
            
            isInitialized = true
            Log.d(TAG, "Extension script loaded successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error loading script: ${e.message}", e)
            // Clean up on failure
            close()
            throw RuntimeException("Failed to load JavaScript extension: ${e.message}", e)
        }
    }
    
    /**
     * Calls a JavaScript function with the provided parameters.
     * 
     * This method:
     * 1. Validates that the engine is initialized
     * 2. Converts Kotlin parameters to JavaScript-compatible format
     * 3. Executes the function in the JS context
     * 4. Returns the result as a JSON string
     * 
     * @param funcName The name of the JavaScript function to call
     * @param params Variable number of parameters to pass to the function
     * @return The function result as a JSON string
     * @throws IllegalStateException if the engine is not initialized
     * @throws RuntimeException if function execution fails
     */
    fun callFunction(funcName: String, vararg params: Any): String {
        if (!isInitialized || quickJs == null) {
            throw IllegalStateException("Engine is not initialized. Call loadScript() first.")
        }
        
        return try {
            Log.d(TAG, "Calling function: $funcName with ${params.size} parameters")
            
            quickJs?.let { js ->
                // Clear previous console logs
                js.evaluate("__consoleLogs = [];")
                
                // Build the JavaScript function call
                val jsParams = params.joinToString(", ") { param ->
                    when (param) {
                        is String -> "\"${escapeJsString(param)}\""
                        is Number -> param.toString()
                        is Boolean -> param.toString()
                        is JSONObject -> param.toString()
                        is JSONArray -> param.toString()
                        else -> "\"${escapeJsString(param.toString())}\""
                    }
                }
                
                // First, call the function and check if it returns a Promise
                val checkCode = """
                    (function() {
                        try {
                            __promiseState = { resolved: false, result: null, error: null };
                            var funcResult = $funcName($jsParams);
                            
                            // Check if result is a Promise
                            if (funcResult && typeof funcResult.then === 'function') {
                                funcResult.then(function(value) {
                                    __promiseState.resolved = true;
                                    __promiseState.result = value;
                                }).catch(function(err) {
                                    __promiseState.resolved = true;
                                    __promiseState.error = err;
                                });
                                return 'PROMISE';
                            } else {
                                return JSON.stringify({
                                    result: funcResult,
                                    logs: __consoleLogs
                                });
                            }
                        } catch (e) {
                            return JSON.stringify({
                                error: true,
                                message: e.message || String(e),
                                stack: e.stack || '',
                                logs: __consoleLogs
                            });
                        }
                    })();
                """.trimIndent()
                
                Log.d(TAG, "Executing JS code: $checkCode")
                val checkResult = js.evaluate(checkCode) as? String ?: "{}"
                
                val resultStr = if (checkResult == "PROMISE") {
                    // It's a promise, we need to execute pending jobs until it resolves
                    Log.d(TAG, "Function returned a Promise, executing pending jobs...")
                    
                    var iterations = 0
                    val maxIterations = 30000 // 30 seconds timeout
                    
                    while (iterations < maxIterations) {
                        // Execute pending jobs (this processes microtasks/promises)
                        try {
                            js.evaluate("void 0;") // Trigger job execution
                        } catch (e: Exception) {
                            Log.w(TAG, "Error executing pending jobs: ${e.message}")
                        }
                        
                        // Check if promise resolved
                        val stateCheck = js.evaluate("__promiseState.resolved") as? Boolean ?: false
                        if (stateCheck) {
                            Log.d(TAG, "Promise resolved after $iterations iterations")
                            break
                        }
                        
                        iterations++
                        Thread.sleep(1) // Small delay to prevent busy-waiting
                    }
                    
                    if (iterations >= maxIterations) {
                        Log.e(TAG, "Promise timeout after 30 seconds")
                        JSONObject().apply {
                            put("error", true)
                            put("message", "Promise timeout after 30 seconds")
                            put("logs", JSONArray())
                        }.toString()
                    } else {
                        // Get the resolved value
                        val getResultCode = """
                            (function() {
                                if (__promiseState.error) {
                                    return JSON.stringify({
                                        error: true,
                                        message: __promiseState.error.message || String(__promiseState.error),
                                        stack: __promiseState.error.stack || '',
                                        logs: __consoleLogs
                                    });
                                } else {
                                    return JSON.stringify({
                                        result: __promiseState.result,
                                        logs: __consoleLogs
                                    });
                                }
                            })();
                        """.trimIndent()
                        
                        js.evaluate(getResultCode) as? String ?: "{}"
                    }
                } else {
                    checkResult
                }
                
                // Parse the result to extract and log console messages
                try {
                    val resultJson = JSONObject(resultStr)
                    val logs = resultJson.optJSONArray("logs")
                    
                    if (logs != null) {
                        for (i in 0 until logs.length()) {
                            val logEntry = logs.getJSONObject(i)
                            val type = logEntry.getString("type")
                            val message = logEntry.getString("message")
                            
                            when (type) {
                                "error" -> Log.e("JS-Console", message)
                                "warn" -> Log.w("JS-Console", message)
                                "info" -> Log.i("JS-Console", message)
                                else -> Log.d("JS-Console", message)
                            }
                        }
                    }
                    
                    // Return just the result part (or error)
                    if (resultJson.has("error")) {
                        resultStr
                    } else {
                        val actualResult = resultJson.opt("result")
                        when (actualResult) {
                            is JSONObject -> actualResult.toString()
                            is JSONArray -> actualResult.toString()
                            is String -> "\"$actualResult\""
                            null -> "{}"
                            else -> JSONObject().put("value", actualResult).toString()
                        }
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to parse console logs: ${e.message}")
                    resultStr
                }
                
            } ?: throw RuntimeException("QuickJS context is null")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error calling function '$funcName': ${e.message}", e)
            
            // Return error as JSON
            val errorJson = JSONObject().apply {
                put("error", true)
                put("message", e.message ?: "Unknown error")
                put("function", funcName)
            }
            
            errorJson.toString()
        }
    }
    
    /**
     * Closes and cleans up the QuickJS context.
     * 
     * This method MUST be called when the engine is no longer needed to prevent memory leaks.
     * It's safe to call this method multiple times.
     */
    fun close() {
        try {
            if (quickJs != null) {
                Log.d(TAG, "Destroying QuickJS context...")
                quickJs?.close()
                quickJs = null
                isInitialized = false
                Log.d(TAG, "QuickJS context destroyed successfully")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error closing QuickJS context: ${e.message}", e)
        } finally {
            // Ensure cleanup even if close() throws
            quickJs = null
            isInitialized = false
        }
    }
    
    /**
     * Escapes special characters in a string for safe use in JavaScript code.
     * 
     * @param str The string to escape
     * @return The escaped string
     */
    private fun escapeJsString(str: String): String {
        return str
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    }
    
    /**
     * Checks if the engine is currently initialized and ready to execute functions.
     * 
     * @return true if initialized, false otherwise
     */
    fun isReady(): Boolean {
        return isInitialized && quickJs != null
    }
}
