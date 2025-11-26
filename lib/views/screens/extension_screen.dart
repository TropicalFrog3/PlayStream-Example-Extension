import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/extension/extension_info.dart';
import '../../models/extension/extension_metadata.dart';
import '../../services/extension/extension_manager.dart';
import '../widgets/app_bottom_nav_bar.dart';
import 'extension_sandbox_screen.dart';

/// Provider for available extensions list
final availableExtensionsProvider = FutureProvider.autoDispose<List<ExtensionInfo>>((ref) async {
  final manager = ref.watch(extensionManagerProvider);
  return await manager.fetchAvailableExtensions();
});

/// Provider for installed extensions list
final installedExtensionsProvider = Provider<List<ExtensionMetadata>>((ref) {
  final manager = ref.watch(extensionManagerProvider);
  return manager.getInstalledExtensions();
});

/// Provider for available updates map
final availableUpdatesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final manager = ref.watch(extensionManagerProvider);
  return await manager.checkForUpdates();
});

/// Extension Screen UI for browsing, downloading, and managing extensions
class ExtensionScreen extends ConsumerStatefulWidget {
  const ExtensionScreen({super.key});

  @override
  ConsumerState<ExtensionScreen> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends ConsumerState<ExtensionScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOfflineMode = false;
  
  // Track download progress for each extension
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};
  final Map<String, bool> _isInstalling = {};
  final Map<String, String?> _operationErrors = {};

  @override
  void initState() {
    super.initState();
    _loadExtensions();
  }

  /// Load extensions from GitHub repository
  Future<void> _loadExtensions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isOfflineMode = false;
    });

    try {
      // Trigger the provider to fetch extensions
      await ref.read(availableExtensionsProvider.future);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load extensions: $e';
        _isOfflineMode = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Refresh extensions list (pull-to-refresh)
  Future<void> _refreshExtensions() async {
    try {
      final manager = ref.read(extensionManagerProvider);
      
      // Clear the manifest cache to ensure fresh data
      await manager.clearManifestCache();
      
      // Fetch with force refresh
      await manager.fetchAvailableExtensions(forceRefresh: true);
      
      // Refresh the provider
      ref.invalidate(availableExtensionsProvider);
      ref.invalidate(availableUpdatesProvider);
      
      setState(() {
        _errorMessage = null;
        _isOfflineMode = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh extensions: $e';
        _isOfflineMode = true;
      });
    }
  }

  /// Navigate to Extension Sandbox screen
  void _navigateToSandbox() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ExtensionSandboxScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableExtensionsAsync = ref.watch(availableExtensionsProvider);
    final installedExtensions = ref.watch(installedExtensionsProvider);
    final availableUpdatesAsync = ref.watch(availableUpdatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extensions'),
        actions: [
          if (_isOfflineMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Extension Sandbox',
            onPressed: _navigateToSandbox,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshExtensions,
          ),
        ],
      ),
      body: _buildBody(availableExtensionsAsync, installedExtensions, availableUpdatesAsync),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/extensions'),
    );
  }

  Widget _buildBody(
    AsyncValue<List<ExtensionInfo>> availableExtensionsAsync,
    List<ExtensionMetadata> installedExtensions,
    AsyncValue<Map<String, String>> availableUpdatesAsync,
  ) {
    // Show error message if present
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    // Show loading indicator during initial load
    if (_isLoading && availableExtensionsAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return availableExtensionsAsync.when(
      data: (availableExtensions) {
        if (availableExtensions.isEmpty) {
          return _buildEmptyView();
        }

        final updates = availableUpdatesAsync.value ?? {};

        return RefreshIndicator(
          onRefresh: _refreshExtensions,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableExtensions.length,
            itemBuilder: (context, index) {
              final extension = availableExtensions[index];
              final installedMetadata = installedExtensions
                  .where((e) => e.id == extension.id)
                  .firstOrNull;
              final hasUpdate = updates.containsKey(extension.id);

              return _buildExtensionCard(
                extension,
                installedMetadata,
                hasUpdate,
                updates[extension.id],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorView(error: error.toString()),
    );
  }

  Widget _buildErrorView({String? error}) {
    final displayError = error ?? _errorMessage ?? 'An unknown error occurred';
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Extensions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              displayError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshExtensions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            if (_isOfflineMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Offline mode: Showing cached data',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.extension_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Extensions Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for available extensions',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionCard(
    ExtensionInfo extension,
    ExtensionMetadata? installedMetadata,
    bool hasUpdate,
    String? updateVersion,
  ) {
    final isInstalled = installedMetadata != null;
    final manager = ref.read(extensionManagerProvider);
    final isProblematic = isInstalled && manager.isExtensionProblematic(extension.id);
    final consecutiveFailures = isInstalled ? manager.getConsecutiveFailures(extension.id) : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show problematic extension warning
            if (isProblematic)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Extension is experiencing issues',
                            style: TextStyle(
                              color: Colors.red[300],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This extension has failed $consecutiveFailures consecutive times. '
                      'Consider reinstalling it to fix potential issues.',
                      style: TextStyle(
                        color: Colors.red[200],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _reinstallExtension(extension),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Reinstall Extension'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[300],
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            // Extension header with icon, name, and version
            Row(
              children: [
                // Extension icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: extension.iconUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.extension, size: 24),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.extension, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Extension name and version
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        extension.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'v${extension.version}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          if (isInstalled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                'Installed',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[300],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (hasUpdate) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.orange),
                              ),
                              child: Text(
                                'Update Available',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[300],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Extension description
            Text(
              extension.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            // Extension size
            Text(
              'Size: ${_formatBytes(extension.size)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            if (isInstalled)
              _buildInstalledActions(extension, installedMetadata, hasUpdate, updateVersion)
            else
              _buildDownloadButton(extension),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(ExtensionInfo extension) {
    final isDownloading = _isDownloading[extension.id] ?? false;
    final isInstalling = _isInstalling[extension.id] ?? false;
    final progress = _downloadProgress[extension.id] ?? 0.0;
    final error = _operationErrors[extension.id];

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _downloadAndInstall(extension),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (isInstalling) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            'Installing...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
            ),
          ),
        ],
      );
    }

    if (isDownloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text(
            'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _downloadAndInstall(extension),
        icon: const Icon(Icons.download),
        label: const Text('Download'),
      ),
    );
  }

  /// Download and install an extension
  Future<void> _downloadAndInstall(ExtensionInfo extension) async {
    setState(() {
      _isDownloading[extension.id] = true;
      _downloadProgress[extension.id] = 0.0;
      _operationErrors.remove(extension.id);
    });

    try {
      final manager = ref.read(extensionManagerProvider);

      // Download the extension
      final apkPath = await manager.downloadExtension(
        extension.id,
        extension.downloadUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[extension.id] = progress;
          });
        },
      );

      // Update state to installing
      setState(() {
        _isDownloading[extension.id] = false;
        _isInstalling[extension.id] = true;
      });

      // Install the extension
      final success = await manager.installExtension(
        extension.id,
        apkPath,
        extension.name,
        extension.version,
      );

      if (success) {
        setState(() {
          _isInstalling[extension.id] = false;
        });

        // Refresh the installed extensions list
        ref.invalidate(installedExtensionsProvider);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${extension.name} installed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Installation returned false');
      }
    } catch (e) {
      setState(() {
        _isDownloading[extension.id] = false;
        _isInstalling[extension.id] = false;
        _operationErrors[extension.id] = 'Failed to install: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to install ${extension.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInstalledActions(
    ExtensionInfo extension,
    ExtensionMetadata installedMetadata,
    bool hasUpdate,
    String? updateVersion,
  ) {
    final isUpdating = _isDownloading[extension.id] ?? false;
    final updateProgress = _downloadProgress[extension.id] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Show update button if update is available
        if (hasUpdate && !isUpdating)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _updateExtension(extension),
              icon: const Icon(Icons.system_update),
              label: Text('Update to v$updateVersion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
            ),
          ),
        
        // Show update progress
        if (isUpdating)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                LinearProgressIndicator(value: updateProgress),
                const SizedBox(height: 4),
                Text(
                  'Updating... ${(updateProgress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

        // Enable/Disable toggle and Uninstall button
        Row(
          children: [
            // Enable/Disable toggle with label
            Expanded(
              child: Row(
                children: [
                  Switch(
                    value: installedMetadata.isEnabled,
                    onChanged: (value) => _toggleExtension(extension.id, value),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    installedMetadata.isEnabled ? 'Enabled' : 'Disabled',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Uninstall button
            ElevatedButton.icon(
              onPressed: () => _showUninstallConfirmation(extension, installedMetadata),
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Uninstall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Toggle extension enabled/disabled state
  Future<void> _toggleExtension(String extensionId, bool enabled) async {
    try {
      final manager = ref.read(extensionManagerProvider);
      await manager.setExtensionEnabled(extensionId, enabled);

      // Refresh the installed extensions list
      ref.invalidate(installedExtensionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Extension enabled' : 'Extension disabled'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle extension: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show confirmation dialog before uninstalling
  Future<void> _showUninstallConfirmation(
    ExtensionInfo extension,
    ExtensionMetadata installedMetadata,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall Extension'),
        content: Text(
          'Are you sure you want to uninstall ${extension.name}? '
          'This will remove the extension and all its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _uninstallExtension(extension);
    }
  }

  /// Uninstall an extension
  Future<void> _uninstallExtension(ExtensionInfo extension) async {
    try {
      final manager = ref.read(extensionManagerProvider);
      await manager.uninstallExtension(extension.id);

      // Refresh the installed extensions list
      ref.invalidate(installedExtensionsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${extension.name} uninstalled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to uninstall ${extension.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Update an extension to the latest version
  Future<void> _updateExtension(ExtensionInfo extension) async {
    setState(() {
      _isDownloading[extension.id] = true;
      _downloadProgress[extension.id] = 0.0;
      _operationErrors.remove(extension.id);
    });

    try {
      final manager = ref.read(extensionManagerProvider);

      final success = await manager.updateExtension(
        extension.id,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[extension.id] = progress;
          });
        },
      );

      setState(() {
        _isDownloading[extension.id] = false;
      });

      if (success) {
        // Refresh providers
        ref.invalidate(installedExtensionsProvider);
        ref.invalidate(availableUpdatesProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${extension.name} updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading[extension.id] = false;
        _operationErrors[extension.id] = 'Failed to update: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ${extension.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Reinstall a problematic extension
  Future<void> _reinstallExtension(ExtensionInfo extension) async {
    try {
      final manager = ref.read(extensionManagerProvider);

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reinstall Extension'),
          content: Text(
            'This will uninstall and reinstall ${extension.name}. '
            'Your preferences will be preserved. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reinstall'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Uninstall first
      await manager.uninstallExtension(extension.id);

      // Then download and install
      setState(() {
        _isDownloading[extension.id] = true;
        _downloadProgress[extension.id] = 0.0;
        _operationErrors.remove(extension.id);
      });

      final apkPath = await manager.downloadExtension(
        extension.id,
        extension.downloadUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[extension.id] = progress;
          });
        },
      );

      setState(() {
        _isDownloading[extension.id] = false;
        _isInstalling[extension.id] = true;
      });

      final success = await manager.installExtension(
        extension.id,
        apkPath,
        extension.name,
        extension.version,
      );

      setState(() {
        _isInstalling[extension.id] = false;
      });

      if (success) {
        // Refresh the installed extensions list
        ref.invalidate(installedExtensionsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${extension.name} reinstalled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading[extension.id] = false;
        _isInstalling[extension.id] = false;
        _operationErrors[extension.id] = 'Failed to reinstall: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reinstall ${extension.name}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
