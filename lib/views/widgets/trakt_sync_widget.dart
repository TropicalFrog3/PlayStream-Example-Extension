import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/trakt_sync_controller.dart';
import '../../core/config/app_config.dart';
import '../../core/config/trakt_config.dart';
import '../../services/platform/url_launcher_service.dart';

class TraktSyncWidget extends ConsumerWidget {
  const TraktSyncWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isTraktConnectedProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final syncState = ref.watch(traktSyncStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Trakt Sync',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!isConnected) ...[
              const Text(
                'Connect your Trakt account to sync your watched history and watchlist.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showConnectDialog(context, ref),
                icon: const Icon(Icons.link),
                label: const Text('Connect Trakt'),
              ),
            ] else ...[
              profileAsync.when(
                data: (profile) {
                  if (profile == null) return const SizedBox();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Connected as ${profile.traktUsername}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (profile.lastTraktSync != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last synced: ${_formatDateTime(profile.lastTraktSync!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      if (syncState.watchedMoviesCount != null ||
                          syncState.watchedShowsCount != null ||
                          syncState.watchlistMoviesCount != null ||
                          syncState.watchlistShowsCount != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Sync Statistics',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatRow(
                            'Watched Movies', syncState.watchedMoviesCount),
                        _buildStatRow(
                            'Watched Shows', syncState.watchedShowsCount),
                        _buildStatRow('Watchlist Movies',
                            syncState.watchlistMoviesCount),
                        _buildStatRow(
                            'Watchlist Shows', syncState.watchlistShowsCount),
                        const SizedBox(height: 8),
                      ],

                      const Divider(),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: syncState.isSyncing
                                ? null
                                : () => _syncNow(ref),
                            icon: syncState.isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(
                              syncState.isSyncing ? 'Syncing...' : 'Sync Now',
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: syncState.isSyncing
                                ? null
                                : () => _disconnectTrakt(context, ref),
                            icon: const Icon(Icons.link_off),
                            label: const Text('Disconnect'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      if (syncState.lastSyncMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          syncState.lastSyncMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading profile'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int? count) {
    if (count == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _showConnectDialog(BuildContext context, WidgetRef ref) async {
    final authUrl = '${TraktConfig.oauth2AuthorizationUrl}'
        '?client_id=${AppConfig.traktClientId}'
        '&redirect_uri=${AppConfig.traktRedirectUri}'
        '&response_type=code';

    // Try to launch the URL automatically
    final launched = await UrlLauncherService.launchUrl(authUrl);

    if (!launched) {
      // If launch failed, show manual copy option
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser automatically. Please copy the URL manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    // Wait a moment for the browser to open, then show the code input dialog
    await Future.delayed(const Duration(milliseconds: 500));

    if (context.mounted) {
      _showCodeInputDialog(context, ref, authUrl);
    }
  }

  void _showCodeInputDialog(BuildContext context, WidgetRef ref, String authUrl) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.blue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enter Authorization Code',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'After authorizing on Trakt, paste the code here:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Authorization Code',
                  hintText: 'Paste code here',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.vpn_key),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 1,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context);
                    _handleConnect(context, ref, value.trim());
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Need help?',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: authUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy', style: TextStyle(fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await UrlLauncherService.launchUrl(authUrl);
                    },
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text('Open', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter the authorization code'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _handleConnect(context, ref, code);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleConnect(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Connecting to Trakt...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    final notifier = ref.read(traktSyncStateProvider.notifier);
    final success = await notifier.connectTrakt(code);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully connected to Trakt!'
                : 'Failed to connect. Please check the code and try again.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Syncing your data...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );

        await notifier.syncAll();
      }
    }
  }

  Future<void> _syncNow(WidgetRef ref) async {
    final notifier = ref.read(traktSyncStateProvider.notifier);
    await notifier.syncAll();
  }

  Future<void> _disconnectTrakt(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Trakt?'),
        content: const Text(
          'Are you sure you want to disconnect your Trakt account? '
          'Your local data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(traktSyncStateProvider.notifier);
      final success = await notifier.disconnectTrakt();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Disconnected from Trakt'
                  : 'Failed to disconnect from Trakt',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
