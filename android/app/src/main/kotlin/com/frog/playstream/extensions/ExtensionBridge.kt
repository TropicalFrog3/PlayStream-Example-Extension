package com.frog.playstream.extensions

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.json.JSONArray
import java.io.File

/**
 * Bridge between Flutter and native Android extension system.
 * Handles method calls from Flutter via MethodChannel.
 */
class ExtensionBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    
    private val extensionRegistry = ExtensionRegistry()
    private val extensionLoader = ExtensionLoader(context)
    
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "installExtension" -> installExtension(call, result)
                "uninstallExtension" -> uninstallExtension(call, result)
                "invokeProvider" -> invokeProvider(call, result)
                "executeDynamicCode" -> executeDynamicCode(call, result)
                "runExtensionMethod" -> runExtensionMethod(call, result)
                "listExtensions" -> listExtensions(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("BRIDGE_ERROR", "Unexpected error: ${e.message}", e.stackTraceToString())
        }
    }
    
    /**
     * Install an extension from an APK file
     */
    private fun installExtension(call: MethodCall, result: MethodChannel.Result) {
        try {
            val extensionId = call.argument<String>("extensionId")
            val apkPath = call.argument<String>("apkPath")
            
            if (extensionId == null || apkPath == null) {
                result.error("INVALID_ARGUMENTS", "extensionId and apkPath are required", null)
                return
            }
            
            if (extensionRegistry.contains(extensionId)) {
                result.error("ALREADY_INSTALLED", "Extension $extensionId is already installed", null)
                return
            }
            
            val provider = extensionLoader.loadExtension(apkPath)
            
            if (provider.extensionId != extensionId) {
                result.error(
                    "ID_MISMATCH",
                    "Provider extensionId (${provider.extensionId}) does not match expected ($extensionId)",
                    null
                )
                return
            }
            
            extensionRegistry.register(extensionId, provider)
            
            val response = mapOf(
                "success" to true,
                "extensionId" to provider.extensionId,
                "name" to provider.name,
                "version" to provider.version
            )
            result.success(response)
            
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_PROVIDER", e.message ?: "Invalid provider", e.stackTraceToString())
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", "Failed to install extension: ${e.message}", e.stackTraceToString())
        }
    }
    
    /**
     * Uninstall an extension
     */
    private fun uninstallExtension(call: MethodCall, result: MethodChannel.Result) {
        try {
            val extensionId = call.argument<String>("extensionId")
            
            if (extensionId == null) {
                result.error("INVALID_ARGUMENTS", "extensionId is required", null)
                return
            }
            
            if (!extensionRegistry.contains(extensionId)) {
                result.error("NOT_FOUND", "Extension $extensionId is not installed", null)
                return
            }
            
            val removed = extensionRegistry.unregister(extensionId)
            
            if (removed) {
                result.success(mapOf("success" to true, "extensionId" to extensionId))
            } else {
                result.error("UNINSTALL_ERROR", "Failed to unregister extension", null)
            }
            
        } catch (e: Exception) {
            result.error("UNINSTALL_ERROR", "Failed to uninstall extension: ${e.message}", e.stackTraceToString())
        }
    }

    /**
     * Helper function to extract search parameters from args
     */
    private fun extractSearchParams(args: Map<String, Any>?): SearchParams {
        val searchOptionsMap = args?.get("searchOptions") as? Map<*, *>
        
        return if (searchOptionsMap != null) {
            // Extract from SearchOptions
            val query = searchOptionsMap["query"] as? String
                ?: throw IllegalArgumentException("query is required for search")
            val mediaMap = searchOptionsMap["media"] as? Map<*, *>
            SearchParams(
                query = query,
                imdbId = mediaMap?.get("imdbId") as? String,
                tmdbId = mediaMap?.get("tmdbId")?.toString(),
                mediaType = mediaMap?.get("format") as? String
            )
        } else {
            // Old direct parameters
            val query = args?.get("query") as? String
                ?: throw IllegalArgumentException("query is required for search")
            SearchParams(
                query = query,
                imdbId = args?.get("imdbId") as? String,
                tmdbId = args?.get("tmdbId") as? String,
                mediaType = args?.get("mediaType") as? String
            )
        }
    }
    
    /**
     * Helper function to extract episode ID from args
     */
    private fun extractEpisodeId(args: Map<String, Any>?): String {
        val episodeMap = args?.get("episode") as? Map<*, *>
        return if (episodeMap != null) {
            episodeMap["id"] as? String
                ?: throw IllegalArgumentException("episode.id is required for findEpisodeServer")
        } else {
            args?.get("episodeId") as? String
                ?: throw IllegalArgumentException("episodeId is required for findEpisodeServer")
        }
    }
    
    /**
     * Helper data class for search parameters
     */
    private data class SearchParams(
        val query: String,
        val imdbId: String?,
        val tmdbId: String?,
        val mediaType: String?
    )
    
    /**
     * Execute a provider method with the given args
     */
    private fun executeProviderMethod(
        provider: IExtensionProvider,
        method: String,
        args: Map<String, Any>?
    ): String {
        return when (method) {
            "search" -> {
                val params = extractSearchParams(args)
                provider.search(params.query, params.imdbId, params.tmdbId, params.mediaType)
            }
            "findEpisodes" -> {
                val id = args?.get("id") as? String
                    ?: args?.get("showId") as? String
                    ?: throw IllegalArgumentException("id is required for findEpisodes")
                provider.findEpisodes(id)
            }
            "findEpisodeServer" -> {
                val episodeId = extractEpisodeId(args)
                provider.findEpisodeServer(episodeId)
            }
            "getSettings" -> {
                provider.getSettings()
            }
            else -> throw IllegalArgumentException("Unknown method: $method")
        }
    }

    /**
     * Invoke a method on a provider
     */
    private fun invokeProvider(call: MethodCall, result: MethodChannel.Result) {
        val logCapture = ConsoleLogCapture()
        
        try {
            val extensionId = call.argument<String>("extensionId")
            val method = call.argument<String>("method")
            val args = call.argument<Map<String, Any>>("args")
            val captureConsoleLogs = call.argument<Boolean>("captureConsoleLogs") ?: false
            
            if (extensionId == null || method == null) {
                result.error("INVALID_ARGUMENTS", "extensionId and method are required", null)
                return
            }
            
            val provider = extensionRegistry.get(extensionId)
            if (provider == null) {
                result.error("NOT_FOUND", "Extension $extensionId is not installed", null)
                return
            }
            
            if (captureConsoleLogs) {
                logCapture.startCapture()
            }
            
            val response = try {
                executeProviderMethod(provider, method, args)
            } catch (e: IllegalArgumentException) {
                if (captureConsoleLogs) {
                    logCapture.stopCapture()
                    val errorResponse = mapOf(
                        "success" to false,
                        "error" to (e.message ?: "Invalid arguments"),
                        "logs" to logCapture.getLogsAsMap()
                    )
                    result.success(errorResponse)
                } else {
                    result.error("INVALID_ARGUMENTS", e.message ?: "Invalid arguments", null)
                }
                return
            } finally {
                if (captureConsoleLogs) {
                    logCapture.stopCapture()
                }
            }
            
            if (captureConsoleLogs) {
                val responseMap = mapOf(
                    "success" to true,
                    "output" to response,
                    "logs" to logCapture.getLogsAsMap()
                )
                result.success(responseMap)
            } else {
                result.success(response)
            }
            
        } catch (e: Exception) {
            if (call.argument<Boolean>("captureConsoleLogs") == true) {
                logCapture.stopCapture()
                val errorResponse = mapOf(
                    "success" to false,
                    "error" to "Failed to invoke provider method: ${e.message}",
                    "logs" to logCapture.getLogsAsMap()
                )
                result.success(errorResponse)
            } else {
                result.error("INVOKE_ERROR", "Failed to invoke provider method: ${e.message}", e.stackTraceToString())
            }
        }
    }

    /**
     * Execute dynamic Kotlin code
     */
    private fun executeDynamicCode(call: MethodCall, result: MethodChannel.Result) {
        val logCapture = ConsoleLogCapture()
        
        try {
            val kotlinCode = call.argument<String>("kotlinCode")
            val method = call.argument<String>("method")
            val args = call.argument<Map<String, Any>>("args")
            val captureConsoleLogs = call.argument<Boolean>("captureConsoleLogs") ?: false
            
            if (kotlinCode == null || method == null) {
                result.error("INVALID_ARGUMENTS", "kotlinCode and method are required", null)
                return
            }
            
            if (captureConsoleLogs) {
                logCapture.startCapture()
            }
            
            val provider = try {
                extensionLoader.loadDynamicCode(kotlinCode)
            } catch (e: Exception) {
                if (captureConsoleLogs) {
                    logCapture.stopCapture()
                    val errorResponse = mapOf(
                        "success" to false,
                        "error" to "Compilation error: ${e.message}",
                        "logs" to logCapture.getLogsAsMap()
                    )
                    result.success(errorResponse)
                } else {
                    result.error("COMPILATION_ERROR", "Failed to compile code: ${e.message}", e.stackTraceToString())
                }
                return
            }
            
            val response = try {
                executeProviderMethod(provider, method, args)
            } catch (e: IllegalArgumentException) {
                if (captureConsoleLogs) {
                    logCapture.stopCapture()
                    val errorResponse = mapOf(
                        "success" to false,
                        "error" to (e.message ?: "Invalid arguments"),
                        "logs" to logCapture.getLogsAsMap()
                    )
                    result.success(errorResponse)
                } else {
                    result.error("INVALID_ARGUMENTS", e.message ?: "Invalid arguments", null)
                }
                return
            } finally {
                if (captureConsoleLogs) {
                    logCapture.stopCapture()
                }
            }
            
            if (captureConsoleLogs) {
                val responseMap = mapOf(
                    "success" to true,
                    "output" to response,
                    "logs" to logCapture.getLogsAsMap()
                )
                result.success(responseMap)
            } else {
                result.success(response)
            }
            
        } catch (e: Exception) {
            if (call.argument<Boolean>("captureConsoleLogs") == true) {
                logCapture.stopCapture()
                val errorResponse = mapOf(
                    "success" to false,
                    "error" to "Failed to execute code: ${e.message}",
                    "logs" to logCapture.getLogsAsMap()
                )
                result.success(errorResponse)
            } else {
                result.error("EXECUTION_ERROR", "Failed to execute code: ${e.message}", e.stackTraceToString())
            }
        }
    }

    /**
     * List all installed extensions
     */
    private fun listExtensions(result: MethodChannel.Result) {
        try {
            val extensionIds = extensionRegistry.list()
            
            val extensions = extensionIds.mapNotNull { id ->
                val provider = extensionRegistry.get(id)
                provider?.let {
                    mapOf(
                        "extensionId" to it.extensionId,
                        "name" to it.name,
                        "version" to it.version
                    )
                }
            }
            
            result.success(extensions)
            
        } catch (e: Exception) {
            result.error("LIST_ERROR", "Failed to list extensions: ${e.message}", e.stackTraceToString())
        }
    }
    
    /**
     * Run a JavaScript extension method using the JS engine
     */
    private fun runExtensionMethod(call: MethodCall, result: MethodChannel.Result) {
        val engine = JsExtensionEngine(context)
        
        try {
            val code = call.argument<String>("code")
            val function = call.argument<String>("function")
            val args = call.argument<List<Any>>("args")
            
            if (code == null || function == null) {
                result.error("INVALID_ARGUMENTS", "code and function are required", null)
                return
            }
            
            engine.loadScript(code)
            
            val functionArgs = args?.toTypedArray() ?: emptyArray()
            val response = engine.callFunction(function, *functionArgs)
            
            try {
                val jsonResponse = JSONObject(response)
                if (jsonResponse.optBoolean("error", false)) {
                    result.error(
                        "JS_ERROR",
                        jsonResponse.optString("message", "Unknown JavaScript error"),
                        jsonResponse.optString("stack", null)
                    )
                    return
                }
            } catch (e: Exception) {
                // Response is not JSON or doesn't have error field, treat as success
            }
            
            result.success(response)
            
        } catch (e: IllegalStateException) {
            result.error("ENGINE_ERROR", e.message ?: "Engine state error", e.stackTraceToString())
        } catch (e: Exception) {
            result.error("EXECUTION_ERROR", "Failed to execute JS method: ${e.message}", e.stackTraceToString())
        } finally {
            engine.close()
        }
    }
}
