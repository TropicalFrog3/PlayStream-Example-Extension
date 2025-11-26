import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/extension/extension_info.dart';
import '../../models/extension/extension_metadata.dart';
import '../../models/extension/extension_preferences.dart';
import '../../models/extension/cache_entry.dart';
import '../../models/extension/extension_exception.dart';
import '../../models/extension/search_result.dart';
import '../../models/extension/movie_details.dart';
import '../../models/extension/episode_details.dart';
import '../../models/extension/stream_server.dart';
import '../../models/extension/episode_server.dart';
import '../../models/extension/search_options.dart';
import '../../models/extension/extension_settings.dart';
import '../../models/extension/sandbox_execution_result.dart';
import '../../models/extension/console_log_entry.dart';

/// Provider for the ExtensionManager singleton instance
final extensionManagerProvider = Provider<ExtensionManager>((ref) {
  throw UnimplementedError('ExtensionManager must be initialized in main.dart');
});

/// Central service that manages all extension operations including
/// downloading, installing, uninstalling, and invoking extension providers.
class ExtensionManager {
  static const MethodChannel _channel = MethodChannel('com.playstream/extensions');
  
  final Box<ExtensionMetadata> _extensionBox;
  final Box<ExtensionInfo> _availableExtensionsBox;
  final Box<ExtensionPreferences> _preferencesBox;
  final Box<CacheEntry> _cacheBox;
  final Dio _dio;
  final Logger _logger;
  
  final List<String> _enabledExtensions = [];
  
  // Cache expiration durations
  static const Duration _manifestCacheExpiration = Duration(hours: 1);
  static const Duration _searchCacheExpiration = Duration(minutes: 5);
  static const Duration _serverCacheExpiration = Duration(minutes: 30);
  static const Duration _settingsCacheExpiration = Duration(hours: 1);
  
  ExtensionManager._({
    required Box<ExtensionMetadata> extensionBox,
    required Box<ExtensionInfo> availableExtensionsBox,
    required Box<ExtensionPreferences> preferencesBox,
    required Box<CacheEntry> cacheBox,
    required Dio dio,
    required Logger logger,
  })  : _extensionBox = extensionBox,
        _availableExtensionsBox = availableExtensionsBox,
        _preferencesBox = preferencesBox,
        _cacheBox = cacheBox,
        _dio = dio,
        _logger = logger {
    _loadEnabledExtensions();
  }

  /// Factory constructor to create and initialize ExtensionManager
  static Future<ExtensionManager> create() async {
    // Open Hive boxes for extension data
    final extensionBox = await Hive.openBox<ExtensionMetadata>('extensions');
    final availableExtensionsBox = await Hive.openBox<ExtensionInfo>('available_extensions');
    final preferencesBox = await Hive.openBox<ExtensionPreferences>('extension_preferences');
    final cacheBox = await Hive.openBox<CacheEntry>('extension_cache');
    
    // Initialize Dio for network requests
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    // Initialize Logger
    final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );
    
    return ExtensionManager._(
      extensionBox: extensionBox,
      availableExtensionsBox: availableExtensionsBox,
      preferencesBox: preferencesBox,
      cacheBox: cacheBox,
      dio: dio,
      logger: logger,
    );
  }

  /// Load enabled extensions from Hive storage
  void _loadEnabledExtensions() {
    _enabledExtensions.clear();
    for (var metadata in _extensionBox.values) {
      if (metadata.isEnabled) {
        _enabledExtensions.add(metadata.id);
      }
    }
    _logger.i('Loaded ${_enabledExtensions.length} enabled extensions');
  }

  /// Get list of installed extensions
  List<ExtensionMetadata> getInstalledExtensions() {
    return _extensionBox.values.toList();
  }

  /// Get list of enabled extension IDs
  List<String> getEnabledExtensions() {
    return List.unmodifiable(_enabledExtensions);
  }

  /// Get metadata for a specific extension
  ExtensionMetadata? getExtensionMetadata(String extensionId) {
    return _extensionBox.get(extensionId);
  }

  /// Check if an extension is installed
  bool isExtensionInstalled(String extensionId) {
    return _extensionBox.containsKey(extensionId);
  }

  /// Check if an extension is enabled
  bool isExtensionEnabled(String extensionId) {
    return _enabledExtensions.contains(extensionId);
  }

  // GitHub repository configuration
  static const String _manifestUrl = 'https://raw.githubusercontent.com/TropicalFrog3/PlayStream-Extensions/refs/heads/main/extensions_manifest.json';

  /// Fetch available extensions from GitHub repository with caching
  /// 
  /// Returns a list of [ExtensionInfo] objects representing available extensions.
  /// Implements 1-hour caching to reduce network requests.
  /// Throws [ExtensionException] on network failures with retry logic.
  Future<List<ExtensionInfo>> fetchAvailableExtensions({bool forceRefresh = false}) async {
    _logger.d('Fetching available extensions (forceRefresh: $forceRefresh)');
    
    const cacheKey = 'manifest';
    
    // Check cache validity
    if (!forceRefresh) {
      final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
      if (cachedEntry != null) {
        _logger.i('Using cached extension list (age: ${cachedEntry.age.inMinutes} minutes)');
        final extensions = cachedEntry.data
            .map<ExtensionInfo>((json) => ExtensionInfo.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        return extensions;
      }
    }

    try {
      // Fetch manifest from GitHub with retry logic
      final extensions = await _executeWithRetry<List<ExtensionInfo>>(
        () async {
          _logger.d('Fetching extensions manifest from: $_manifestUrl');
          final response = await _dio.get(
            _manifestUrl,
            options: Options(
              responseType: ResponseType.json,
              headers: {'Accept': 'application/json'},
            ),
          );
          
          if (response.statusCode != 200) {
            throw ExtensionException.networkError(
              'Failed to fetch extensions manifest: HTTP ${response.statusCode}',
            );
          }

          // // TODO: remove this once production
          // // Handle both parsed JSON and string responses
          // // Temporary hardcoded data for testing (GitHub raw files don't update instantly)
          // final data = {
          //   "extensions": [
          //     "https://raw.githubusercontent.com/TropicalFrog3/PlayStream-Example-Extension/refs/heads/main/manifest.json"
          //   ]
          // };
          final data = response.data is String 
              ? jsonDecode(response.data as String) 
              : response.data;
          final extensionUrls = (data as Map<String, dynamic>)['extensions'] as List<dynamic>;
          
          _logger.i('Found ${extensionUrls.length} extension manifest URLs');
          
          // Fetch each individual extension manifest
          final extensions = <ExtensionInfo>[];
          for (var url in extensionUrls) {
            try {
              _logger.d('Fetching extension manifest from: $url');
              final extResponse = await _dio.get(
                url as String,
                options: Options(
                  responseType: ResponseType.json,
                  headers: {'Accept': 'application/json'},
                ),
              );
              
              if (extResponse.statusCode == 200) {
                // Handle both parsed JSON and string responses
                final data = extResponse.data is String 
                    ? jsonDecode(extResponse.data as String) 
                    : extResponse.data;
                    
                final extInfo = ExtensionInfo.fromJson(data as Map<String, dynamic>);
                extensions.add(extInfo);
                _logger.d('Successfully fetched extension: ${extInfo.id}');
              } else {
                _logger.w('Failed to fetch extension from $url: HTTP ${extResponse.statusCode}');
              }
            } catch (e) {
              _logger.w('Error fetching extension from $url: $e');
              // Continue with other extensions even if one fails
            }
          }
          
          _logger.i('Successfully fetched ${extensions.length} extensions');
          return extensions;
        },
      );

      // Update cache with 1-hour expiration
      await _setCacheEntry(
        cacheKey,
        extensions.map((e) => e.toJson()).toList(),
        _manifestCacheExpiration,
      );
      
      // Also update the available extensions box for backward compatibility
      await _availableExtensionsBox.clear();
      for (var extension in extensions) {
        await _availableExtensionsBox.put(extension.id, extension);
      }
      
      return extensions;
    } catch (e, stackTrace) {
      _logger.e('Failed to fetch extensions from GitHub', error: e, stackTrace: stackTrace);
      
      // Try to return cached data even if expired
      final cachedEntry = _cacheBox.get(cacheKey);
      if (cachedEntry != null) {
        _logger.w('Returning expired cached extension list due to network error');
        final extensions = (cachedEntry.data as List<dynamic>)
            .map<ExtensionInfo>((json) => ExtensionInfo.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        return extensions;
      }
      
      // Fallback to available extensions box
      if (_availableExtensionsBox.isNotEmpty) {
        _logger.w('Returning extension list from available extensions box');
        return _availableExtensionsBox.values.toList();
      }
      
      throw ExtensionException.networkError(
        'Failed to fetch extensions and no cached data available',
        originalError: e,
      );
    }
  }

  /// Execute an operation with retry logic and exponential backoff
  /// 
  /// Retries the operation up to [maxAttempts] times with exponential delay.
  /// Used for network operations that may fail transiently.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          _logger.e('Max retry attempts ($maxAttempts) reached');
          rethrow;
        }

        _logger.w('Attempt $attempt failed, retrying in ${delay.inSeconds}s: $e');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    throw Exception('Max retry attempts reached');
  }

  // Download management
  final Map<String, CancelToken> _activeDownloads = {};

  /// Download an extension APK from GitHub
  /// 
  /// Downloads the APK file to the app's cache directory with progress tracking.
  /// Supports download cancellation via [CancelToken].
  /// 
  /// [extensionId] - Unique identifier for the extension
  /// [downloadUrl] - URL to download the APK from
  /// [onProgress] - Optional callback for download progress (0.0 to 1.0)
  /// 
  /// Returns the local file path where the APK was saved.
  /// Throws [ExtensionException] on download failures.
  Future<String> downloadExtension(
    String extensionId,
    String downloadUrl, {
    void Function(double progress)? onProgress,
  }) async {
    _logger.i('Starting download for extension: $extensionId');
    _logger.d('Download URL: $downloadUrl');

    try {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      final extensionsDir = Directory('${cacheDir.path}/extensions');
      if (!await extensionsDir.exists()) {
        await extensionsDir.create(recursive: true);
      }

      // Create file path
      final filePath = '${extensionsDir.path}/$extensionId.apk';
      final file = File(filePath);

      // Delete existing file if present
      if (await file.exists()) {
        await file.delete();
        _logger.d('Deleted existing APK file');
      }

      // Create cancel token for this download
      final cancelToken = CancelToken();
      _activeDownloads[extensionId] = cancelToken;

      // Download with retry logic
      await _executeWithRetry(() async {
        _logger.d('Downloading to: $filePath');
        
        await _dio.download(
          downloadUrl,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1 && onProgress != null) {
              final progress = received / total;
              onProgress(progress);
              _logger.d('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
            }
          },
        );
      });

      // Remove from active downloads
      _activeDownloads.remove(extensionId);

      // Verify file exists and has content
      if (!await file.exists()) {
        throw ExtensionException.downloadFailed(
          'Downloaded file does not exist',
          extensionId: extensionId,
        );
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw ExtensionException.downloadFailed(
          'Downloaded file is empty',
          extensionId: extensionId,
        );
      }

      _logger.i('Successfully downloaded extension: $extensionId ($fileSize bytes)');
      return filePath;
    } catch (e, stackTrace) {
      _activeDownloads.remove(extensionId);
      _logger.e('Failed to download extension: $extensionId', error: e, stackTrace: stackTrace);

      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw ExtensionException.downloadFailed(
          'Download cancelled by user',
          extensionId: extensionId,
          originalError: e,
        );
      }

      throw ExtensionException.downloadFailed(
        'Failed to download extension',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Cancel an ongoing download
  /// 
  /// [extensionId] - ID of the extension whose download should be cancelled
  /// Returns true if a download was cancelled, false if no download was in progress
  bool cancelDownload(String extensionId) {
    final cancelToken = _activeDownloads[extensionId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Download cancelled by user');
      _activeDownloads.remove(extensionId);
      _logger.i('Cancelled download for extension: $extensionId');
      return true;
    }
    return false;
  }

  /// Check if a download is in progress for an extension
  bool isDownloading(String extensionId) {
    return _activeDownloads.containsKey(extensionId);
  }

  /// Install an extension from a downloaded APK file
  /// 
  /// Calls the native Android method to load and validate the extension,
  /// then stores the metadata in Hive.
  /// 
  /// [extensionId] - Unique identifier for the extension
  /// [apkPath] - Local file path to the downloaded APK
  /// [name] - Display name of the extension
  /// [version] - Version string of the extension
  /// 
  /// Returns true if installation succeeds.
  /// Throws [ExtensionException] on installation failures with automatic cleanup.
  Future<bool> installExtension(
    String extensionId,
    String apkPath,
    String name,
    String version,
  ) async {
    _logger.i('Installing extension: $extensionId (version: $version)');
    _logger.d('APK path: $apkPath');

    File? apkFile;
    try {
      // Verify APK file exists
      apkFile = File(apkPath);
      if (!await apkFile.exists()) {
        throw ExtensionException.installationFailed(
          'APK file not found at path: $apkPath',
          extensionId: extensionId,
        );
      }

      // Call native method to install extension
      _logger.d('Calling native installExtension method');
      final result = await _channel.invokeMethod('installExtension', {
        'extensionId': extensionId,
        'apkPath': apkPath,
      });

      // Handle different return types from native code
      final success = result is bool ? result : (result is Map ? true : false);
      
      if (!success) {
        throw ExtensionException.installationFailed(
          'Native installation returned false or unexpected result: $result',
          extensionId: extensionId,
        );
      }

      // Create metadata for installed extension
      final metadata = ExtensionMetadata(
        id: extensionId,
        name: name,
        version: version,
        apkPath: apkPath,
        isEnabled: true, // Enable by default
        installedAt: DateTime.now(),
        settings: {},
      );

      // Store metadata in Hive
      await _extensionBox.put(extensionId, metadata);
      
      // Add to enabled extensions list
      if (!_enabledExtensions.contains(extensionId)) {
        _enabledExtensions.add(extensionId);
      }

      // Reset health status on fresh installation
      await resetHealthStatus(extensionId);

      _logger.i('Successfully installed extension: $extensionId');
      return true;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception during installation', error: e, stackTrace: stackTrace);
      
      // Handle ALREADY_INSTALLED case - treat as success and update metadata
      if (e.code == 'ALREADY_INSTALLED') {
        _logger.w('Extension already installed, updating metadata');
        
        // Create/update metadata for the extension
        final metadata = ExtensionMetadata(
          id: extensionId,
          name: name,
          version: version,
          apkPath: apkPath,
          isEnabled: true,
          installedAt: DateTime.now(),
          settings: {},
        );

        // Store metadata in Hive
        await _extensionBox.put(extensionId, metadata);
        
        // Add to enabled extensions list
        if (!_enabledExtensions.contains(extensionId)) {
          _enabledExtensions.add(extensionId);
        }

        // Reset health status
        await resetHealthStatus(extensionId);

        _logger.i('Successfully updated metadata for already installed extension: $extensionId');
        return true;
      }
      
      // Cleanup on failure for other errors
      await _cleanupFailedInstallation(extensionId, apkFile);
      
      throw ExtensionException.installationFailed(
        'Native installation failed: ${e.message}',
        extensionId: extensionId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to install extension', error: e, stackTrace: stackTrace);
      
      // Cleanup on failure
      await _cleanupFailedInstallation(extensionId, apkFile);
      
      if (e is ExtensionException) {
        rethrow;
      }
      
      throw ExtensionException.installationFailed(
        'Installation failed: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Clean up after a failed installation
  Future<void> _cleanupFailedInstallation(String extensionId, File? apkFile) async {
    _logger.d('Cleaning up failed installation for: $extensionId');
    
    try {
      // Remove from Hive if it was added
      await _extensionBox.delete(extensionId);
      
      // Remove from enabled list
      _enabledExtensions.remove(extensionId);
      
      // Delete APK file if it exists
      if (apkFile != null && await apkFile.exists()) {
        await apkFile.delete();
        _logger.d('Deleted APK file during cleanup');
      }
    } catch (e) {
      _logger.w('Error during cleanup: $e');
    }
  }

  /// Uninstall an extension
  /// 
  /// Removes the extension from native registry, deletes the APK file,
  /// and removes metadata from Hive storage.
  /// 
  /// [extensionId] - Unique identifier for the extension to uninstall
  /// 
  /// Returns true if uninstallation succeeds.
  /// Throws [ExtensionException] on uninstallation failures.
  Future<bool> uninstallExtension(String extensionId) async {
    _logger.i('Uninstalling extension: $extensionId');

    // Get metadata before deletion
    final metadata = _extensionBox.get(extensionId);
    if (metadata == null) {
      _logger.w('Extension not found in metadata: $extensionId');
      throw ExtensionException.providerNotFound(extensionId);
    }

    try {
      // Call native method to uninstall extension
      _logger.d('Calling native uninstallExtension method');
      final result = await _channel.invokeMethod('uninstallExtension', {
        'extensionId': extensionId,
      });

      // Handle different return types from native code
      final success = result is bool ? result : (result is Map ? true : false);
      
      if (!success) {
        _logger.w('Native uninstallation returned false or unexpected result: $result');
      }

      // Remove from enabled extensions list
      _enabledExtensions.remove(extensionId);

      // Delete APK file
      final apkFile = File(metadata.apkPath);
      if (await apkFile.exists()) {
        await apkFile.delete();
        _logger.d('Deleted APK file: ${metadata.apkPath}');
      } else {
        _logger.w('APK file not found: ${metadata.apkPath}');
      }

      // Remove metadata from Hive
      await _extensionBox.delete(extensionId);

      // Clear preferences
      await clearPreferences(extensionId);

      _logger.i('Successfully uninstalled extension: $extensionId');
      return true;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception during uninstallation', error: e, stackTrace: stackTrace);
      
      // Handle NOT_FOUND error gracefully - extension not installed on native side
      // but we still need to clean up Flutter-side metadata
      if (e.code == 'NOT_FOUND') {
        _logger.w('Extension not found on native side, cleaning up Flutter metadata');
        
        // Remove from enabled extensions list
        _enabledExtensions.remove(extensionId);

        // Delete APK file if it exists
        final apkFile = File(metadata.apkPath);
        if (await apkFile.exists()) {
          await apkFile.delete();
          _logger.d('Deleted APK file: ${metadata.apkPath}');
        }

        // Remove metadata from Hive
        await _extensionBox.delete(extensionId);

        // Clear preferences
        await clearPreferences(extensionId);

        _logger.i('Successfully cleaned up extension metadata: $extensionId');
        return true;
      }
      
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Native uninstallation failed: ${e.message}',
        extensionId: extensionId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to uninstall extension', error: e, stackTrace: stackTrace);
      
      if (e is ExtensionException) {
        rethrow;
      }
      
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Uninstallation failed: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Enable or disable an extension
  /// 
  /// Updates the extension's enabled state in Hive and the in-memory list.
  /// Disabled extensions are excluded from content searches.
  /// 
  /// [extensionId] - Unique identifier for the extension
  /// [enabled] - True to enable, false to disable
  /// 
  /// Throws [ExtensionException] if the extension is not installed.
  Future<void> setExtensionEnabled(String extensionId, bool enabled) async {
    _logger.i('Setting extension $extensionId enabled state to: $enabled');

    // Get current metadata
    final metadata = _extensionBox.get(extensionId);
    if (metadata == null) {
      throw ExtensionException.providerNotFound(extensionId);
    }

    // Update metadata
    final updatedMetadata = metadata.copyWith(isEnabled: enabled);
    await _extensionBox.put(extensionId, updatedMetadata);

    // Update enabled extensions list
    if (enabled) {
      if (!_enabledExtensions.contains(extensionId)) {
        _enabledExtensions.add(extensionId);
        _logger.d('Added $extensionId to enabled extensions');
      }
    } else {
      _enabledExtensions.remove(extensionId);
      _logger.d('Removed $extensionId from enabled extensions');
    }

    _logger.i('Successfully updated extension enabled state');
  }

  /// Enable an extension
  Future<void> enableExtension(String extensionId) async {
    await setExtensionEnabled(extensionId, true);
  }

  /// Disable an extension
  Future<void> disableExtension(String extensionId) async {
    await setExtensionEnabled(extensionId, false);
  }

  /// Check for available updates for installed extensions
  /// 
  /// Compares installed extension versions with available versions from GitHub.
  /// Returns a map of extension IDs to their available version strings.
  /// Only includes extensions that have updates available.
  /// Updates the last update check timestamp for all checked extensions.
  /// 
  /// Returns empty map if no updates are available or if fetch fails.
  Future<Map<String, String>> checkForUpdates() async {
    _logger.i('Checking for extension updates');

    try {
      // Fetch latest available extensions
      final availableExtensions = await fetchAvailableExtensions();
      
      // Get installed extensions
      final installedExtensions = _extensionBox.values.toList();
      
      final updates = <String, String>{};
      
      for (var installed in installedExtensions) {
        // Update last check timestamp
        await updateLastUpdateCheck(installed.id);
        
        // Find matching available extension
        final available = availableExtensions.firstWhere(
          (ext) => ext.id == installed.id,
          orElse: () => throw StateError('Not found'),
        );
        
        // Compare versions
        if (_isNewerVersion(available.version, installed.version)) {
          updates[installed.id] = available.version;
          _logger.d('Update available for ${installed.id}: ${installed.version} -> ${available.version}');
        }
      }
      
      _logger.i('Found ${updates.length} extension updates');
      return updates;
    } catch (e, stackTrace) {
      _logger.e('Failed to check for updates', error: e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Compare two version strings to determine if the first is newer
  /// 
  /// Simple version comparison assuming semantic versioning (major.minor.patch).
  /// Returns true if [newVersion] is greater than [currentVersion].
  bool _isNewerVersion(String newVersion, String currentVersion) {
    try {
      final newParts = newVersion.split('.').map(int.parse).toList();
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      
      // Pad with zeros if needed
      while (newParts.length < 3) {
        newParts.add(0);
      }
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      
      // Compare major, minor, patch
      for (int i = 0; i < 3; i++) {
        if (newParts[i] > currentParts[i]) return true;
        if (newParts[i] < currentParts[i]) return false;
      }
      
      return false; // Versions are equal
    } catch (e) {
      _logger.w('Failed to parse version strings: $newVersion vs $currentVersion');
      return false;
    }
  }

  /// Update an installed extension to a new version
  /// 
  /// Downloads the new version, backs up current settings, installs the update,
  /// and restores settings. Rolls back to the previous version on failure.
  /// 
  /// [extensionId] - Unique identifier for the extension to update
  /// [onProgress] - Optional callback for download progress (0.0 to 1.0)
  /// 
  /// Returns true if update succeeds.
  /// Throws [ExtensionException] on update failures with automatic rollback.
  Future<bool> updateExtension(
    String extensionId, {
    void Function(double progress)? onProgress,
  }) async {
    _logger.i('Updating extension: $extensionId');

    // Get current metadata
    final currentMetadata = _extensionBox.get(extensionId);
    if (currentMetadata == null) {
      throw ExtensionException.providerNotFound(extensionId);
    }

    // Backup current settings
    final backupSettings = Map<String, dynamic>.from(currentMetadata.settings);
    final backupApkPath = currentMetadata.apkPath;
    final wasEnabled = currentMetadata.isEnabled;
    
    _logger.d('Backed up settings for $extensionId');

    try {
      // Fetch available extensions to get download URL
      final availableExtensions = await fetchAvailableExtensions();
      final availableExtension = availableExtensions.firstWhere(
        (ext) => ext.id == extensionId,
        orElse: () => throw ExtensionException(
          type: ExtensionErrorType.providerNotFound,
          message: 'Extension not found in available extensions',
          extensionId: extensionId,
        ),
      );

      // Check if update is actually needed
      if (!_isNewerVersion(availableExtension.version, currentMetadata.version)) {
        _logger.i('Extension $extensionId is already up to date');
        return false;
      }

      _logger.i('Updating from ${currentMetadata.version} to ${availableExtension.version}');

      // Download new version
      final newApkPath = await downloadExtension(
        extensionId,
        availableExtension.downloadUrl,
        onProgress: onProgress,
      );

      // Uninstall current version (but keep metadata for rollback)
      try {
        await _channel.invokeMethod<bool>('uninstallExtension', {
          'extensionId': extensionId,
        });
      } catch (e) {
        _logger.w('Failed to uninstall old version, continuing: $e');
      }

      // Install new version
      final installResult = await _channel.invokeMethod<bool>('installExtension', {
        'extensionId': extensionId,
        'apkPath': newApkPath,
      });

      if (installResult != true) {
        throw ExtensionException.installationFailed(
          'Failed to install new version',
          extensionId: extensionId,
        );
      }

      // Update metadata with new version and restored settings
      final updatedMetadata = ExtensionMetadata(
        id: extensionId,
        name: availableExtension.name,
        version: availableExtension.version,
        apkPath: newApkPath,
        isEnabled: wasEnabled,
        installedAt: currentMetadata.installedAt,
        settings: backupSettings,
      );

      await _extensionBox.put(extensionId, updatedMetadata);

      // Clear caches for the updated extension
      await invalidateCacheOnUpdate(extensionId);

      // Delete old APK file
      try {
        final oldApkFile = File(backupApkPath);
        if (await oldApkFile.exists()) {
          await oldApkFile.delete();
          _logger.d('Deleted old APK file');
        }
      } catch (e) {
        _logger.w('Failed to delete old APK file: $e');
      }

      _logger.i('Successfully updated extension: $extensionId to version ${availableExtension.version}');
      return true;
    } catch (e, stackTrace) {
      _logger.e('Failed to update extension, attempting rollback', error: e, stackTrace: stackTrace);

      // Attempt rollback
      try {
        await _rollbackUpdate(extensionId, currentMetadata, backupApkPath, backupSettings, wasEnabled);
      } catch (rollbackError) {
        _logger.e('Rollback failed', error: rollbackError);
      }

      if (e is ExtensionException) {
        rethrow;
      }

      throw ExtensionException(
        type: ExtensionErrorType.installationFailed,
        message: 'Update failed: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Rollback a failed update to the previous version
  Future<void> _rollbackUpdate(
    String extensionId,
    ExtensionMetadata previousMetadata,
    String previousApkPath,
    Map<String, dynamic> previousSettings,
    bool wasEnabled,
  ) async {
    _logger.w('Rolling back update for: $extensionId');

    try {
      // Reinstall previous version
      final rollbackResult = await _channel.invokeMethod('installExtension', {
        'extensionId': extensionId,
        'apkPath': previousApkPath,
      });

      // Handle different return types from native code
      final success = rollbackResult is bool ? rollbackResult : (rollbackResult is Map ? true : false);

      if (success) {
        // Restore previous metadata
        await _extensionBox.put(extensionId, previousMetadata);
        
        // Restore enabled state
        if (wasEnabled && !_enabledExtensions.contains(extensionId)) {
          _enabledExtensions.add(extensionId);
        } else if (!wasEnabled) {
          _enabledExtensions.remove(extensionId);
        }
        
        _logger.i('Successfully rolled back to previous version');
      } else {
        _logger.e('Rollback installation failed');
      }
    } catch (e) {
      _logger.e('Exception during rollback: $e');
      rethrow;
    }
  }

  // ========== Provider Method Invocation ==========

  /// Search for content across all enabled extensions
  /// 
  /// Invokes the search method on all enabled extensions in parallel,
  /// aggregates results, and handles individual extension failures gracefully.
  /// Implements a 30-second timeout per extension to prevent indefinite waiting.
  /// Caches search results for 5 minutes to improve performance.
  /// 
  /// [searchOptions] - The search options containing media metadata, query, and optional year
  /// [useCache] - Whether to use cached results (default: true)
  /// 
  /// Returns a list of [SearchResult] objects from all successful extensions.
  /// Individual extension failures are logged but do not prevent other extensions from returning results.
  Future<List<SearchResult>> searchAll(
    SearchOptions searchOptions, {
    bool useCache = true,
  }) async {
    _logger.i('Searching across all enabled extensions for: "${searchOptions.query}" (tmdbId: ${searchOptions.media.tmdbId}, imdbId: ${searchOptions.media.imdbId})');

    if (_enabledExtensions.isEmpty) {
      _logger.w('No enabled extensions available for search');
      return [];
    }

    // Check cache if enabled
    final cacheKey = 'search:${searchOptions.query}';
    // TODO: put if(useCache) in PROD
    if (useCache) {
      final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
      if (cachedEntry != null) {
        _logger.i('Using cached search results (age: ${cachedEntry.age.inSeconds} seconds)');
        final results = cachedEntry.data
            .map<SearchResult>((json) => SearchResult.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        return results;
      }
    }

    _logger.d('Searching across ${_enabledExtensions.length} enabled extensions');

    // Create search tasks for all enabled extensions
    final searchTasks = _enabledExtensions.map((extensionId) {
      return _searchSingleExtension(extensionId, searchOptions);
    }).toList();

    // Execute all searches in parallel and wait for all to complete
    final results = await Future.wait(searchTasks);

    // Flatten the list of lists and filter out nulls
    final allResults = results
        .where((list) => list != null)
        .expand((list) => list!)
        .toList();

    // Cache results for 5 minutes
    await _setCacheEntry(
      cacheKey,
      allResults.map((r) => r.toJson()).toList(),
      _searchCacheExpiration,
    );

    _logger.i('Search completed: ${allResults.length} total results from ${_enabledExtensions.length} extensions');
    return allResults;
  }

  /// Search a single extension with timeout and error handling
  /// 
  /// Returns null if the extension fails or times out, allowing other extensions to continue.
  Future<List<SearchResult>?> _searchSingleExtension(String extensionId, SearchOptions searchOptions) async {
    _logger.d('Searching extension: $extensionId');

    try {
      // Call provider search method with 30-second timeout
      // Send SearchOptions as JSON to the Kotlin side
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'search',
        args: {'opts': searchOptions.toJson()},
        trackHealth: false, // We handle health tracking in this method
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('Search timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'Search operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      // Parse results
      if (result == null) {
        _logger.w('Extension $extensionId returned null result');
        await recordFailure(extensionId, error: 'Null result returned');
        return [];
      }

      final resultList = result as List<dynamic>;
      final searchResults = resultList
          .map((json) => SearchResult.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.d('Extension $extensionId returned ${searchResults.length} results');
      
      // Record success to reset failure count
      await recordSuccess(extensionId);
      
      return searchResults;
    } on ExtensionException catch (e) {
      _logger.w('Extension $extensionId failed during search: ${e.message}');
      await recordFailure(extensionId, error: e);
      return null; // Return null to indicate failure, but don't throw
    } catch (e, stackTrace) {
      _logger.e('Unexpected error searching extension $extensionId', error: e, stackTrace: stackTrace);
      await recordFailure(extensionId, error: e);
      return null; // Return null to indicate failure, but don't throw
    }
  }

  /// Invoke a method on an extension provider via MethodChannel
  /// 
  /// Generic method for calling any provider method through the native bridge.
  /// Records successes and failures for health monitoring.
  /// 
  /// [extensionId] - The extension to invoke
  /// [method] - The method name to call (e.g., 'search', 'findMovie')
  /// [args] - Arguments to pass to the method
  /// [trackHealth] - Whether to track success/failure for health monitoring (default: true)
  /// 
  /// Returns the result from the provider method.
  /// Throws [ExtensionException] on invocation failures.
  Future<dynamic> _invokeProviderMethod({
    required String extensionId,
    required String method,
    required Map<String, dynamic> args,
    bool trackHealth = true,
  }) async {
    _logger.d('Invoking $method on extension $extensionId with args: $args');

    try {
      final result = await _channel.invokeMethod('invokeProvider', {
        'extensionId': extensionId,
        'method': method,
        'args': args,
      });

      _logger.d('Successfully invoked $method on $extensionId');
      
      // Record success for health monitoring (except for search, which handles it separately)
      if (trackHealth && method != 'search') {
        await recordSuccess(extensionId);
      }
      
      return result;
    } on PlatformException catch (e) {
      _logger.e('Platform exception invoking $method on $extensionId: ${e.message}');
      
      // Record failure for health monitoring
      if (trackHealth) {
        await recordFailure(extensionId, error: e);
      }
      
      if (e.code == 'NOT_FOUND') {
        throw ExtensionException.providerNotFound(extensionId);
      }
      
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to invoke $method: ${e.message}',
        extensionId: extensionId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Error invoking $method on $extensionId', error: e, stackTrace: stackTrace);
      
      // Record failure for health monitoring
      if (trackHealth) {
        await recordFailure(extensionId, error: e);
      }
      
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to invoke $method: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find movie details from a specific extension
  /// 
  /// Calls the provider's findMovie method to retrieve detailed information
  /// about a movie including available streaming servers.
  /// Implements timeout and error handling.
  /// 
  /// [extensionId] - The extension to query
  /// [movieId] - The movie identifier from the extension
  /// 
  /// Returns [MovieDetails] with streaming server information.
  /// Throws [ExtensionException] on failures or timeout.
  Future<MovieDetails> findMovie(String extensionId, String movieId) async {
    _logger.i('Finding movie $movieId from extension $extensionId');

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findMovie',
        args: {'movieId': movieId},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findMovie timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findMovie operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'findMovie returned null result',
          extensionId: extensionId,
        );
      }

      final movieDetails = MovieDetails.fromJson(result as Map<String, dynamic>);
      _logger.i('Successfully found movie: ${movieDetails.title}');
      return movieDetails;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding movie $movieId from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find movie: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find episode details from a specific extension (legacy method)
  /// 
  /// Calls the provider's findEpisode method to retrieve detailed information
  /// about a TV show episode including available streaming servers.
  /// Implements timeout and error handling.
  /// 
  /// [extensionId] - The extension to query
  /// [showId] - The TV show identifier from the extension
  /// [season] - The season number
  /// [episode] - The episode number
  /// 
  /// Returns [EpisodeDetails] with streaming server information.
  /// Throws [ExtensionException] on failures or timeout.
  @Deprecated('Use findEpisodes instead for the new MediaProvider interface')
  Future<EpisodeDetails> findEpisode(
    String extensionId,
    String showId,
    int season,
    int episode,
  ) async {
    _logger.i('Finding episode S${season}E$episode of show $showId from extension $extensionId');

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findEpisode',
        args: {
          'showId': showId,
          'season': season,
          'episode': episode,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findEpisode timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findEpisode operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'findEpisode returned null result',
          extensionId: extensionId,
        );
      }

      final episodeDetails = EpisodeDetails.fromJson(result as Map<String, dynamic>);
      _logger.i('Successfully found episode: ${episodeDetails.title}');
      return episodeDetails;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding episode from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find episode: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find episodes for a content ID from a specific extension
  /// 
  /// Calls the provider's findEpisodes method to retrieve a list of episodes
  /// for the given content ID. This is the new MediaProvider interface method.
  /// Implements timeout and error handling.
  /// 
  /// [extensionId] - The extension to query
  /// [id] - The content identifier (from SearchResult.id)
  /// 
  /// Returns a list of [EpisodeDetails] objects.
  /// Returns empty list if no episodes found.
  /// Throws [ExtensionException] on failures or timeout.
  Future<List<EpisodeDetails>> findEpisodes(
    String extensionId,
    String id,
  ) async {
    _logger.i('Finding episodes for content $id from extension $extensionId');

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findEpisodes',
        args: {'id': id},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findEpisodes timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findEpisodes operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        _logger.w('findEpisodes returned null result for $id');
        return [];
      }

      final resultList = result as List<dynamic>;
      final episodes = resultList
          .map((json) => EpisodeDetails.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.i('Successfully found ${episodes.length} episodes for content $id');
      return episodes;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding episodes from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find episodes: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find episode server details from a specific extension
  /// 
  /// Calls the provider's findEpisodeServer method to retrieve streaming server
  /// information for a specific episode. This is the new MediaProvider interface method.
  /// Implements timeout and error handling.
  /// 
  /// [extensionId] - The extension to query
  /// [episode] - The episode details (from findEpisodes)
  /// [server] - The server name to use (from Settings.episodeServers)
  /// 
  /// Returns [EpisodeServer] with video sources and headers.
  /// Throws [ExtensionException] on failures or timeout.
  Future<EpisodeServer> findEpisodeServer(
    String extensionId,
    EpisodeDetails episode,
    String server,
  ) async {
    _logger.i('Finding episode server for episode ${episode.id} with server $server from extension $extensionId');

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findEpisodeServer',
        args: {
          'episode': episode.toJson(),
          'server': server,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findEpisodeServer timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findEpisodeServer operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'findEpisodeServer returned null result',
          extensionId: extensionId,
        );
      }

      final episodeServer = EpisodeServer.fromJson(result as Map<String, dynamic>);
      _logger.i('Successfully found episode server: ${episodeServer.server} with ${episodeServer.videoSources.length} sources');
      return episodeServer;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding episode server from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find episode server: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find available streaming servers for a movie
  /// 
  /// Retrieves the list of streaming servers from a provider for a specific movie.
  /// Implements caching to avoid repeated calls for the same content.
  /// 
  /// [extensionId] - The extension to query
  /// [movieId] - The movie identifier from the extension
  /// [useCache] - Whether to use cached results (default: true)
  /// 
  /// Returns a list of [StreamServer] objects.
  /// Throws [ExtensionException] on failures or timeout.
  Future<List<StreamServer>> findMovieServers(
    String extensionId,
    String movieId, {
    bool useCache = true,
  }) async {
    _logger.i('Finding servers for movie $movieId from extension $extensionId');

    final cacheKey = 'servers:$extensionId:movie:$movieId';

    // Check cache if enabled
    if (useCache) {
      final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
      if (cachedEntry != null) {
        _logger.d('Using cached servers for $cacheKey (age: ${cachedEntry.age.inMinutes} minutes)');
        final servers = cachedEntry.data
            .map<StreamServer>((json) => StreamServer.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        return servers;
      }
    }

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findMovieServers',
        args: {'movieId': movieId},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findMovieServers timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findMovieServers operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'findMovieServers returned null result',
          extensionId: extensionId,
        );
      }

      final resultList = result as List<dynamic>;
      final servers = resultList
          .map((json) => StreamServer.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache with 30-minute expiration
      await _setCacheEntry(
        cacheKey,
        servers.map((s) => s.toJson()).toList(),
        _serverCacheExpiration,
      );

      _logger.i('Successfully found ${servers.length} servers for movie $movieId');
      return servers;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding movie servers from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find movie servers: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  /// Find available streaming servers for a TV show episode
  /// 
  /// Retrieves the list of streaming servers from a provider for a specific episode.
  /// Implements caching to avoid repeated calls for the same content.
  /// 
  /// [extensionId] - The extension to query
  /// [showId] - The TV show identifier from the extension
  /// [season] - The season number
  /// [episode] - The episode number
  /// [useCache] - Whether to use cached results (default: true)
  /// 
  /// Returns a list of [StreamServer] objects.
  /// Throws [ExtensionException] on failures or timeout.
  Future<List<StreamServer>> findEpisodeServers(
    String extensionId,
    String showId,
    int season,
    int episode, {
    bool useCache = true,
  }) async {
    _logger.i('Finding servers for episode S${season}E$episode of show $showId from extension $extensionId');

    final cacheKey = 'servers:$extensionId:episode:$showId:S${season}E$episode';

    // Check cache if enabled
    if (useCache) {
      final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
      if (cachedEntry != null) {
        _logger.d('Using cached servers for $cacheKey (age: ${cachedEntry.age.inMinutes} minutes)');
        final servers = cachedEntry.data
            .map<StreamServer>((json) => StreamServer.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        return servers;
      }
    }

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'findEpisodeServers',
        args: {
          'showId': showId,
          'season': season,
          'episode': episode,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('findEpisodeServers timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'findEpisodeServers operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'findEpisodeServers returned null result',
          extensionId: extensionId,
        );
      }

      final resultList = result as List<dynamic>;
      final servers = resultList
          .map((json) => StreamServer.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache with 30-minute expiration
      await _setCacheEntry(
        cacheKey,
        servers.map((s) => s.toJson()).toList(),
        _serverCacheExpiration,
      );

      _logger.i('Successfully found ${servers.length} servers for episode S${season}E$episode');
      return servers;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error finding episode servers from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to find episode servers: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }



  /// Get settings and configuration from an extension provider
  /// 
  /// Retrieves the extension's settings including available servers and configuration options.
  /// Implements caching to avoid repeated calls.
  /// 
  /// [extensionId] - The extension to query
  /// [useCache] - Whether to use cached results (default: true)
  /// 
  /// Returns [ExtensionSettings] with configuration and available servers.
  /// Throws [ExtensionException] on failures or timeout.
  Future<ExtensionSettings> getSettings(
    String extensionId, {
    bool useCache = true,
  }) async {
    _logger.i('Getting settings for extension $extensionId');

    final cacheKey = 'settings:$extensionId';

    // Check cache if enabled
    if (useCache) {
      final cachedEntry = _getCacheEntry<Map<String, dynamic>>(cacheKey);
      if (cachedEntry != null) {
        _logger.d('Using cached settings for $extensionId (age: ${cachedEntry.age.inMinutes} minutes)');
        return ExtensionSettings.fromJson(Map<String, dynamic>.from(cachedEntry.data));
      }
    }

    try {
      final result = await _invokeProviderMethod(
        extensionId: extensionId,
        method: 'getSettings',
        args: {},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('getSettings timeout for extension: $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'getSettings operation timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      if (result == null) {
        throw ExtensionException(
          type: ExtensionErrorType.methodCallFailed,
          message: 'getSettings returned null result',
          extensionId: extensionId,
        );
      }

      final settings = ExtensionSettings.fromJson(result as Map<String, dynamic>);

      // Update cache with 1-hour expiration
      await _setCacheEntry(
        cacheKey,
        settings.toJson(),
        _settingsCacheExpiration,
      );

      _logger.i('Successfully retrieved settings for extension $extensionId');
      return settings;
    } catch (e, stackTrace) {
      if (e is ExtensionException) {
        rethrow;
      }
      
      _logger.e('Error getting settings from $extensionId', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get settings: $e',
        extensionId: extensionId,
        originalError: e,
      );
    }
  }

  // ========== Sandbox Execution ==========

  /// Execute a sandbox test for a specific extension method
  /// 
  /// Invokes the specified method on an extension with the provided arguments
  /// and returns both the result and captured console logs. This method is designed
  /// for testing and debugging extensions in the Extension Sandbox UI.
  /// 
  /// Implements a 30-second timeout to prevent indefinite waiting.
  /// Captures console logs from the native layer during execution.
  /// Does not track health status to avoid marking extensions as problematic during testing.
  /// 
  /// [extensionId] - The extension to test
  /// [method] - The method name to invoke (e.g., 'search', 'findEpisode', 'findEpisodeServers')
  /// [args] - Arguments for the method
  /// 
  /// Returns a [SandboxExecutionResult] with output and console logs.
  /// Never throws - all errors are captured in the result object.
  Future<SandboxExecutionResult> executeSandboxTest({
    required String extensionId,
    required String method,
    required Map<String, dynamic> args,
  }) async {
    _logger.i('Executing sandbox test: $method on extension $extensionId with args: $args');

    try {
      // Call the native method with captureConsoleLogs flag to capture console logs
      final result = await _channel.invokeMethod('invokeProvider', {
        'extensionId': extensionId,
        'method': method,
        'args': args,
        'captureConsoleLogs': true,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('Sandbox execution timeout for $method on $extensionId');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'Sandbox execution timed out after 30 seconds',
            extensionId: extensionId,
          );
        },
      );

      _logger.d('Sandbox execution completed for $method on $extensionId');

      // Parse the result which should contain both output and logs
      if (result is Map) {
        final resultMap = Map<String, dynamic>.from(result);
        
        // Parse console logs
        final logs = <ConsoleLogEntry>[];
        if (resultMap['logs'] != null) {
          final logsList = resultMap['logs'] as List<dynamic>;
          for (var logData in logsList) {
            try {
              final logMap = Map<String, dynamic>.from(logData as Map);
              logs.add(ConsoleLogEntry.fromJson(logMap));
            } catch (e) {
              _logger.w('Failed to parse console log entry: $e');
            }
          }
        }

        // Check if execution was successful
        final success = resultMap['success'] as bool? ?? false;
        
        if (success) {
          _logger.i('Sandbox execution successful: ${logs.length} console logs captured');
          return SandboxExecutionResult.success(
            output: resultMap['output'],
            consoleLogs: logs,
          );
        } else {
          final errorMessage = resultMap['error'] as String? ?? 'Unknown error occurred';
          _logger.w('Sandbox execution failed: $errorMessage');
          return SandboxExecutionResult.failure(
            errorMessage: errorMessage,
            consoleLogs: logs,
          );
        }
      }

      // Fallback: if result is not a map, treat it as direct output with no logs
      _logger.w('Sandbox execution returned unexpected format, treating as direct output');
      return SandboxExecutionResult.success(
        output: result,
        consoleLogs: [],
      );

    } on PlatformException catch (e) {
      _logger.e('Platform exception during sandbox execution: ${e.message}');
      
      String errorMessage;
      if (e.code == 'NOT_FOUND') {
        errorMessage = 'Extension not found: $extensionId';
      } else if (e.code == 'METHOD_NOT_FOUND') {
        errorMessage = 'Method not found: $method';
      } else {
        errorMessage = 'Platform error: ${e.message ?? e.code}';
      }
      
      return SandboxExecutionResult.failure(
        errorMessage: errorMessage,
        consoleLogs: [],
      );
    } on ExtensionException catch (e) {
      _logger.e('Extension exception during sandbox execution: ${e.message}');
      
      return SandboxExecutionResult.failure(
        errorMessage: e.message,
        consoleLogs: [],
      );
    } catch (e, stackTrace) {
      _logger.e('Unexpected error during sandbox execution', error: e, stackTrace: stackTrace);
      
      return SandboxExecutionResult.failure(
        errorMessage: 'Unexpected error: $e',
        consoleLogs: [],
      );
    }
  }

  /// Execute dynamic Kotlin code in the sandbox
  /// 
  /// Compiles and executes the provided Kotlin code dynamically.
  /// This is useful for testing extension code without installing an APK.
  /// 
  /// Returns a [SandboxExecutionResult] with output and console logs.
  /// Never throws - all errors are captured in the result object.
  Future<SandboxExecutionResult> executeDynamicCode({
    required String kotlinCode,
    required String method,
    required Map<String, dynamic> args,
  }) async {
    _logger.i('Executing dynamic Kotlin code: $method with args: $args');

    try {
      // Call the native method to compile and execute dynamic code
      final result = await _channel.invokeMethod('executeDynamicCode', {
        'kotlinCode': kotlinCode,
        'method': method,
        'args': args,
        'captureConsoleLogs': true,
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.w('Dynamic code execution timeout for $method');
          throw ExtensionException(
            type: ExtensionErrorType.timeout,
            message: 'Code execution timed out after 30 seconds',
          );
        },
      );

      _logger.d('Dynamic code execution completed for $method');

      // Parse the result which should contain both output and logs
      if (result is Map) {
        final resultMap = Map<String, dynamic>.from(result);
        
        // Parse console logs
        final logs = <ConsoleLogEntry>[];
        if (resultMap['logs'] != null) {
          final logsList = resultMap['logs'] as List<dynamic>;
          for (var logData in logsList) {
            try {
              final logMap = Map<String, dynamic>.from(logData as Map);
              logs.add(ConsoleLogEntry.fromJson(logMap));
            } catch (e) {
              _logger.w('Failed to parse console log entry: $e');
            }
          }
        }

        // Check if execution was successful
        final success = resultMap['success'] as bool? ?? false;
        
        if (success) {
          _logger.i('Dynamic code execution successful: ${logs.length} console logs captured');
          return SandboxExecutionResult.success(
            output: resultMap['output'],
            consoleLogs: logs,
          );
        } else {
          final errorMessage = resultMap['error'] as String? ?? 'Unknown error occurred';
          _logger.w('Dynamic code execution failed: $errorMessage');
          return SandboxExecutionResult.failure(
            errorMessage: errorMessage,
            consoleLogs: logs,
          );
        }
      }

      // Fallback: if result is not a map, treat it as direct output with no logs
      _logger.w('Dynamic code execution returned unexpected format, treating as direct output');
      return SandboxExecutionResult.success(
        output: result,
        consoleLogs: [],
      );

    } on PlatformException catch (e) {
      _logger.e('Platform exception during dynamic code execution: ${e.message}');
      
      String errorMessage;
      if (e.code == 'COMPILATION_ERROR') {
        errorMessage = 'Compilation error: ${e.message}';
      } else if (e.code == 'METHOD_NOT_FOUND') {
        errorMessage = 'Method not found: $method';
      } else {
        errorMessage = 'Platform error: ${e.message ?? e.code}';
      }
      
      return SandboxExecutionResult.failure(
        errorMessage: errorMessage,
        consoleLogs: [],
      );
    } on ExtensionException catch (e) {
      _logger.e('Extension exception during dynamic code execution: ${e.message}');
      
      return SandboxExecutionResult.failure(
        errorMessage: e.message,
        consoleLogs: [],
      );
    } catch (e, stackTrace) {
      _logger.e('Unexpected error during dynamic code execution', error: e, stackTrace: stackTrace);
      
      return SandboxExecutionResult.failure(
        errorMessage: 'Unexpected error: $e',
        consoleLogs: [],
      );
    }
  }

  // ========== Cache Management ==========

  /// Get a cache entry if it exists and is valid
  /// 
  /// Returns the cache entry if it exists and hasn't expired, null otherwise.
  CacheEntry<T>? _getCacheEntry<T>(String key) {
    final entry = _cacheBox.get(key);
    if (entry != null && entry.isValid) {
      // Create a new CacheEntry with the correct type
      return CacheEntry<T>(
        key: entry.key,
        data: entry.data as T,
        timestamp: entry.timestamp,
        expirationDuration: entry.expirationDuration,
      );
    }
    return null;
  }

  /// Set a cache entry with expiration
  /// 
  /// Stores data in the cache with the specified expiration duration.
  Future<void> _setCacheEntry(
    String key,
    dynamic data,
    Duration expiration,
  ) async {
    final entry = CacheEntry(
      key: key,
      data: data,
      timestamp: DateTime.now(),
      expirationDuration: expiration,
    );
    await _cacheBox.put(key, entry);
  }

  /// Clear all caches
  /// 
  /// Removes all cached data including search results, server lists, and settings.
  Future<void> clearAllCaches() async {
    await _cacheBox.clear();
    _logger.i('Cleared all caches');
  }

  /// Clear cache for a specific extension
  /// 
  /// Removes all cached data related to the specified extension.
  /// This includes search results, server lists, and settings.
  /// 
  /// [extensionId] - The extension whose cache should be cleared
  Future<void> clearCacheForExtension(String extensionId) async {
    final keysToRemove = <String>[];
    
    for (var key in _cacheBox.keys) {
      final keyStr = key.toString();
      // Remove entries that contain the extension ID
      if (keyStr.contains(':$extensionId:') || 
          keyStr.endsWith(':$extensionId') ||
          keyStr == 'settings:$extensionId') {
        keysToRemove.add(keyStr);
      }
    }
    
    for (var key in keysToRemove) {
      await _cacheBox.delete(key);
    }
    
    _logger.i('Cleared cache for extension: $extensionId (${keysToRemove.length} entries)');
  }

  /// Clear manifest cache
  /// 
  /// Removes the cached extension manifest list.
  Future<void> clearManifestCache() async {
    await _cacheBox.delete('manifest');
    _logger.i('Cleared manifest cache');
  }

  /// Clear search cache
  /// 
  /// Removes all cached search results.
  Future<void> clearSearchCache() async {
    final keysToRemove = <String>[];
    
    for (var key in _cacheBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('search:')) {
        keysToRemove.add(keyStr);
      }
    }
    
    for (var key in keysToRemove) {
      await _cacheBox.delete(key);
    }
    
    _logger.d('Cleared search cache (${keysToRemove.length} entries)');
  }

  /// Clear server cache
  /// 
  /// Removes all cached server lists.
  Future<void> clearServerCache() async {
    final keysToRemove = <String>[];
    
    for (var key in _cacheBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('servers:')) {
        keysToRemove.add(keyStr);
      }
    }
    
    for (var key in keysToRemove) {
      await _cacheBox.delete(key);
    }
    
    _logger.d('Cleared server cache (${keysToRemove.length} entries)');
  }

  /// Clear settings cache
  /// 
  /// Removes all cached extension settings.
  Future<void> clearSettingsCache() async {
    final keysToRemove = <String>[];
    
    for (var key in _cacheBox.keys) {
      final keyStr = key.toString();
      if (keyStr.startsWith('settings:')) {
        keysToRemove.add(keyStr);
      }
    }
    
    for (var key in keysToRemove) {
      await _cacheBox.delete(key);
    }
    
    _logger.d('Cleared settings cache (${keysToRemove.length} entries)');
  }

  /// Clear expired cache entries
  /// 
  /// Removes all cache entries that have expired.
  /// This is useful for periodic cleanup to free up storage.
  Future<void> clearExpiredCache() async {
    final keysToRemove = <String>[];
    
    for (var key in _cacheBox.keys) {
      final entry = _cacheBox.get(key);
      if (entry != null && !entry.isValid) {
        keysToRemove.add(key.toString());
      }
    }
    
    for (var key in keysToRemove) {
      await _cacheBox.delete(key);
    }
    
    _logger.d('Cleared expired cache entries (${keysToRemove.length} entries)');
  }

  /// Invalidate cache on extension update
  /// 
  /// Clears all caches for an extension when it's updated.
  /// This ensures that old cached data doesn't interfere with the new version.
  /// 
  /// [extensionId] - The extension that was updated
  Future<void> invalidateCacheOnUpdate(String extensionId) async {
    await clearCacheForExtension(extensionId);
    _logger.i('Invalidated cache for updated extension: $extensionId');
  }

  // ========== Extension Preferences Management ==========

  /// Get preferences for an extension
  /// 
  /// Returns the stored preferences for the specified extension.
  /// Creates a new preferences object if none exists.
  /// 
  /// [extensionId] - The extension to get preferences for
  /// 
  /// Returns [ExtensionPreferences] with server preferences and update check timestamp.
  ExtensionPreferences getPreferences(String extensionId) {
    var prefs = _preferencesBox.get(extensionId);
    if (prefs == null) {
      prefs = ExtensionPreferences(
        extensionId: extensionId,
        serverPreferences: {},
        lastUpdateCheck: null,
      );
      _preferencesBox.put(extensionId, prefs);
      _logger.d('Created new preferences for extension: $extensionId');
    }
    return prefs;
  }

  /// Set server preference for specific content
  /// 
  /// Stores the user's preferred server for a specific piece of content.
  /// This allows the app to remember which server the user prefers for each movie/episode.
  /// 
  /// [extensionId] - The extension that provides the server
  /// [contentId] - Unique identifier for the content (e.g., "movie:123" or "show:456:S1E1")
  /// [serverId] - The ID of the preferred server
  Future<void> setServerPreference(
    String extensionId,
    String contentId,
    String serverId,
  ) async {
    _logger.d('Setting server preference for $extensionId:$contentId -> $serverId');
    
    final prefs = getPreferences(extensionId);
    final updatedServerPrefs = Map<String, String>.from(prefs.serverPreferences);
    updatedServerPrefs[contentId] = serverId;
    
    final updatedPrefs = prefs.copyWith(serverPreferences: updatedServerPrefs);
    await _preferencesBox.put(extensionId, updatedPrefs);
    
    _logger.i('Updated server preference for $extensionId:$contentId');
  }

  /// Get server preference for specific content
  /// 
  /// Retrieves the user's preferred server for a specific piece of content.
  /// Returns null if no preference has been set.
  /// 
  /// [extensionId] - The extension that provides the server
  /// [contentId] - Unique identifier for the content
  /// 
  /// Returns the server ID if a preference exists, null otherwise.
  String? getServerPreference(String extensionId, String contentId) {
    final prefs = getPreferences(extensionId);
    return prefs.serverPreferences[contentId];
  }

  /// Clear server preference for specific content
  /// 
  /// Removes the stored server preference for a specific piece of content.
  /// 
  /// [extensionId] - The extension that provides the server
  /// [contentId] - Unique identifier for the content
  Future<void> clearServerPreference(String extensionId, String contentId) async {
    _logger.d('Clearing server preference for $extensionId:$contentId');
    
    final prefs = getPreferences(extensionId);
    final updatedServerPrefs = Map<String, String>.from(prefs.serverPreferences);
    updatedServerPrefs.remove(contentId);
    
    final updatedPrefs = prefs.copyWith(serverPreferences: updatedServerPrefs);
    await _preferencesBox.put(extensionId, updatedPrefs);
    
    _logger.i('Cleared server preference for $extensionId:$contentId');
  }

  /// Update last update check timestamp for an extension
  /// 
  /// Records when the extension was last checked for updates.
  /// Used to implement periodic update checking without overwhelming the server.
  /// 
  /// [extensionId] - The extension to update the timestamp for
  Future<void> updateLastUpdateCheck(String extensionId) async {
    _logger.d('Updating last update check timestamp for $extensionId');
    
    final prefs = getPreferences(extensionId);
    final updatedPrefs = prefs.copyWith(lastUpdateCheck: DateTime.now());
    await _preferencesBox.put(extensionId, updatedPrefs);
    
    _logger.d('Updated last update check for $extensionId');
  }

  /// Get last update check timestamp for an extension
  /// 
  /// Returns when the extension was last checked for updates.
  /// Returns null if the extension has never been checked.
  /// 
  /// [extensionId] - The extension to get the timestamp for
  /// 
  /// Returns the DateTime of the last check, or null if never checked.
  DateTime? getLastUpdateCheck(String extensionId) {
    final prefs = getPreferences(extensionId);
    return prefs.lastUpdateCheck;
  }

  /// Clear all preferences for an extension
  /// 
  /// Removes all stored preferences for the specified extension.
  /// Useful when an extension is uninstalled.
  /// 
  /// [extensionId] - The extension whose preferences should be cleared
  Future<void> clearPreferences(String extensionId) async {
    await _preferencesBox.delete(extensionId);
    _logger.i('Cleared all preferences for extension: $extensionId');
  }

  // ========== Extension Health Monitoring ==========

  /// Record a successful operation for an extension
  /// 
  /// Resets the consecutive failure count when an extension operation succeeds.
  /// This helps track extension reliability and identify problematic extensions.
  /// 
  /// [extensionId] - The extension that succeeded
  Future<void> recordSuccess(String extensionId) async {
    final prefs = getPreferences(extensionId);
    
    // Only update if there were previous failures
    if (prefs.consecutiveFailures > 0 || prefs.isProblematic) {
      _logger.d('Recording success for $extensionId, resetting failure count');
      
      final updatedPrefs = prefs.copyWith(
        consecutiveFailures: 0,
        isProblematic: false,
        lastFailureTime: null,
      );
      await _preferencesBox.put(extensionId, updatedPrefs);
      
      _logger.i('Extension $extensionId recovered from problematic state');
    }
  }

  /// Record a failure for an extension
  /// 
  /// Increments the consecutive failure count and marks the extension as problematic
  /// after 5 consecutive failures. This helps identify unreliable extensions.
  /// 
  /// [extensionId] - The extension that failed
  /// [error] - The error that occurred (optional, for logging)
  Future<void> recordFailure(String extensionId, {dynamic error}) async {
    final prefs = getPreferences(extensionId);
    final newFailureCount = prefs.consecutiveFailures + 1;
    final isNowProblematic = newFailureCount >= 5;
    
    _logger.w('Recording failure for $extensionId (count: $newFailureCount)${error != null ? ': $error' : ''}');
    
    final updatedPrefs = prefs.copyWith(
      consecutiveFailures: newFailureCount,
      lastFailureTime: DateTime.now(),
      isProblematic: isNowProblematic,
    );
    await _preferencesBox.put(extensionId, updatedPrefs);
    
    if (isNowProblematic && !prefs.isProblematic) {
      _logger.e('Extension $extensionId marked as PROBLEMATIC after $newFailureCount consecutive failures');
    }
  }

  /// Check if an extension is problematic
  /// 
  /// Returns true if the extension has been marked as problematic due to
  /// consecutive failures (5 or more).
  /// 
  /// [extensionId] - The extension to check
  /// 
  /// Returns true if the extension is problematic, false otherwise.
  bool isExtensionProblematic(String extensionId) {
    final prefs = getPreferences(extensionId);
    return prefs.isProblematic;
  }

  /// Get the consecutive failure count for an extension
  /// 
  /// Returns the number of consecutive failures for the extension.
  /// This count is reset when the extension succeeds.
  /// 
  /// [extensionId] - The extension to check
  /// 
  /// Returns the consecutive failure count.
  int getConsecutiveFailures(String extensionId) {
    final prefs = getPreferences(extensionId);
    return prefs.consecutiveFailures;
  }

  /// Get the last failure time for an extension
  /// 
  /// Returns when the extension last failed, or null if it has never failed.
  /// 
  /// [extensionId] - The extension to check
  /// 
  /// Returns the DateTime of the last failure, or null if never failed.
  DateTime? getLastFailureTime(String extensionId) {
    final prefs = getPreferences(extensionId);
    return prefs.lastFailureTime;
  }

  /// Get all problematic extensions
  /// 
  /// Returns a list of extension IDs that are currently marked as problematic.
  /// Useful for displaying warnings to users.
  /// 
  /// Returns a list of problematic extension IDs.
  List<String> getProblematicExtensions() {
    final problematic = <String>[];
    
    for (var extensionId in _extensionBox.keys) {
      if (isExtensionProblematic(extensionId.toString())) {
        problematic.add(extensionId.toString());
      }
    }
    
    _logger.d('Found ${problematic.length} problematic extensions');
    return problematic;
  }

  /// Reset health status for an extension
  /// 
  /// Clears the failure count and problematic status for an extension.
  /// Useful after reinstalling an extension or when the user wants to give it another chance.
  /// 
  /// [extensionId] - The extension to reset
  Future<void> resetHealthStatus(String extensionId) async {
    _logger.i('Resetting health status for extension: $extensionId');
    
    final prefs = getPreferences(extensionId);
    final updatedPrefs = prefs.copyWith(
      consecutiveFailures: 0,
      isProblematic: false,
      lastFailureTime: null,
    );
    await _preferencesBox.put(extensionId, updatedPrefs);
    
    _logger.i('Health status reset for extension: $extensionId');
  }
}
