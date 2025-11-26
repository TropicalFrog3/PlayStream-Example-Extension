package com.frog.playstream.extensions

import android.content.Context
import android.content.pm.PackageManager
import dalvik.system.DexClassLoader
import java.io.File

/**
 * Handles dynamic loading of extension APK files using DexClassLoader.
 */
class ExtensionLoader(private val context: Context) {
    
    /**
     * Load an extension from an APK file
     * @param apkPath Path to the APK file
     * @return Instance of the provider class
     * @throws IllegalArgumentException if the APK doesn't contain a valid provider
     * @throws ClassNotFoundException if the provider class cannot be found
     * @throws Exception for other loading errors
     */
    fun loadExtension(apkPath: String): IExtensionProvider {
        try {
            // Validate that the APK file exists
            val apkFile = File(apkPath)
            if (!apkFile.exists()) {
                throw IllegalArgumentException("APK file does not exist: $apkPath")
            }
            
            // Copy APK to code cache directory (read-only location) to satisfy Android security
            val codeCacheDir = context.codeCacheDir
            val secureApkFile = File(codeCacheDir, "secure_${apkFile.name}")
            
            // Copy the APK if it doesn't exist or is different
            if (!secureApkFile.exists() || secureApkFile.length() != apkFile.length()) {
                apkFile.copyTo(secureApkFile, overwrite = true)
                // Make the file read-only
                secureApkFile.setReadOnly()
            }
            
            // Create optimized dex output directory
            val dexOutputDir = File(codeCacheDir, "extension_dex")
            if (!dexOutputDir.exists()) {
                dexOutputDir.mkdirs()
            }
            
            // Create DexClassLoader to load classes from the APK
            // Use the secure copy instead of the original writable path
            val classLoader = DexClassLoader(
                secureApkFile.absolutePath,
                dexOutputDir.absolutePath,
                null,
                context.classLoader
            )
            
            // Get the provider class name from the APK's AndroidManifest metadata
            val providerClassName = getProviderClassName(secureApkFile.absolutePath)
            
            // Try to load the Provider class
            val providerClass = try {
                classLoader.loadClass(providerClassName)
            } catch (e: ClassNotFoundException) {
                throw IllegalArgumentException(
                    "APK does not contain a Provider class at $providerClassName",
                    e
                )
            }
            
            // Validate that the class implements IExtensionProvider
            if (!IExtensionProvider::class.java.isAssignableFrom(providerClass)) {
                throw IllegalArgumentException(
                    "Provider class does not implement IExtensionProvider interface"
                )
            }
            
            // Create an instance of the provider
            val constructor = providerClass.getDeclaredConstructor()
            constructor.isAccessible = true
            val instance = constructor.newInstance()
            
            // Cast to IExtensionProvider
            return instance as IExtensionProvider
            
        } catch (e: IllegalArgumentException) {
            throw e
        } catch (e: ClassNotFoundException) {
            throw IllegalArgumentException("Failed to load provider class from APK", e)
        } catch (e: Exception) {
            throw Exception("Failed to load extension from APK: ${e.message}", e)
        }
    }
    
    /**
     * Load an extension from dynamic Kotlin code
     * 
     * This method compiles and loads Kotlin code at runtime for testing purposes.
     * Note: This requires the Kotlin compiler to be available at runtime.
     * 
     * @param kotlinCode The Kotlin source code containing the provider implementation
     * @return Instance of the provider class
     * @throws IllegalArgumentException if the code doesn't contain a valid provider
     * @throws Exception for compilation or loading errors
     */
    fun loadDynamicCode(kotlinCode: String): IExtensionProvider {
        try {
            // For now, we'll use a simplified approach that doesn't require runtime compilation
            // Instead, we'll create a temporary APK-like structure
            
            // This is a placeholder implementation
            // In a production environment, you would need to:
            // 1. Use the Kotlin compiler API to compile the code
            // 2. Create a DEX file from the compiled classes
            // 3. Load the DEX file using DexClassLoader
            
            throw UnsupportedOperationException(
                "Dynamic code compilation is not yet implemented. " +
                "This feature requires the Kotlin compiler to be available at runtime. " +
                "Please use the 'Select Extension' mode to test installed extensions."
            )
            
        } catch (e: Exception) {
            throw Exception("Failed to load dynamic code: ${e.message}", e)
        }
    }
    
    /**
     * Validate an APK file without loading it
     * @param apkPath Path to the APK file
     * @return true if the APK contains a valid provider class
     */
    fun validateExtension(apkPath: String): Boolean {
        return try {
            loadExtension(apkPath)
            true
        } catch (e: Exception) {
            false
        }
    }
    
    /**
     * Get the provider class name from the APK's AndroidManifest metadata
     * @param apkPath Path to the APK file
     * @return The fully qualified provider class name
     * @throws IllegalArgumentException if metadata is not found
     */
    private fun getProviderClassName(apkPath: String): String {
        try {
            val packageManager = context.packageManager
            val packageInfo = packageManager.getPackageArchiveInfo(
                apkPath,
                PackageManager.GET_META_DATA
            ) ?: throw IllegalArgumentException("Failed to read APK package info")
            
            val metadata = packageInfo.applicationInfo?.metaData
            val providerClassName = metadata?.getString("extension.provider.class")
            
            if (providerClassName.isNullOrEmpty()) {
                throw IllegalArgumentException(
                    "APK does not contain 'extension.provider.class' metadata in AndroidManifest"
                )
            }
            
            return providerClassName
        } catch (e: Exception) {
            throw IllegalArgumentException("Failed to read provider class from APK manifest: ${e.message}", e)
        }
    }
}
