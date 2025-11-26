package com.frog.playstream.extensions

import java.util.concurrent.ConcurrentHashMap

/**
 * Thread-safe registry for storing and managing loaded extension provider instances.
 */
class ExtensionRegistry {
    private val providers = ConcurrentHashMap<String, IExtensionProvider>()
    
    /**
     * Register a provider instance with the given extension ID
     * @param extensionId Unique identifier for the extension
     * @param provider The provider instance to register
     */
    fun register(extensionId: String, provider: IExtensionProvider) {
        providers[extensionId] = provider
    }
    
    /**
     * Get a provider instance by extension ID
     * @param extensionId Unique identifier for the extension
     * @return The provider instance, or null if not found
     */
    fun get(extensionId: String): IExtensionProvider? {
        return providers[extensionId]
    }
    
    /**
     * Unregister a provider by extension ID
     * @param extensionId Unique identifier for the extension
     * @return true if the provider was removed, false if it didn't exist
     */
    fun unregister(extensionId: String): Boolean {
        return providers.remove(extensionId) != null
    }
    
    /**
     * List all registered extension IDs
     * @return List of extension IDs
     */
    fun list(): List<String> {
        return providers.keys.toList()
    }
    
    /**
     * Check if an extension is registered
     * @param extensionId Unique identifier for the extension
     * @return true if the extension is registered
     */
    fun contains(extensionId: String): Boolean {
        return providers.containsKey(extensionId)
    }
    
    /**
     * Clear all registered providers
     */
    fun clear() {
        providers.clear()
    }
    
    /**
     * Get the number of registered providers
     * @return Number of registered providers
     */
    fun size(): Int {
        return providers.size
    }
}
