import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/extension/stream_server.dart';

/// Dialog for selecting a streaming server from available options
/// Groups servers by extension and persists user preferences
class ServerSelectionDialog extends StatefulWidget {
  final Map<String, List<StreamServer>> serversByExtension;
  final String contentId; // Unique identifier for the content (movie/episode)
  final Function(StreamServer) onServerSelected;

  const ServerSelectionDialog({
    super.key,
    required this.serversByExtension,
    required this.contentId,
    required this.onServerSelected,
  });

  @override
  State<ServerSelectionDialog> createState() => _ServerSelectionDialogState();
}

class _ServerSelectionDialogState extends State<ServerSelectionDialog> {
  String? _selectedServerId;
  late Box<String> _preferencesBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _preferencesBox = await Hive.openBox<String>('server_preferences');
      
      // Load previously selected server for this content
      final savedServerId = _preferencesBox.get(widget.contentId);
      if (savedServerId != null) {
        setState(() {
          _selectedServerId = savedServerId;
        });
      }
    } catch (e) {
      debugPrint('Error loading server preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String serverId) async {
    try {
      await _preferencesBox.put(widget.contentId, serverId);
    } catch (e) {
      debugPrint('Error saving server preference: $e');
    }
  }

  void _selectServer(StreamServer server) {
    setState(() {
      _selectedServerId = server.id;
    });
    _savePreference(server.id);
    widget.onServerSelected(server);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading servers...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dns, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Select Server',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Server list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.serversByExtension.length,
                itemBuilder: (context, index) {
                  final extensionId = widget.serversByExtension.keys.elementAt(index);
                  final servers = widget.serversByExtension[extensionId]!;

                  return _buildExtensionGroup(extensionId, servers);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionGroup(String extensionId, List<StreamServer> servers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extension header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[200],
          child: Row(
            children: [
              Icon(Icons.extension, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                extensionId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${servers.length} server${servers.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Server list for this extension
        ...servers.map((server) => _buildServerTile(server)),
        
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildServerTile(StreamServer server) {
    final isSelected = _selectedServerId == server.id;

    return ListTile(
      leading: Icon(
        _getIconForServerType(server.type),
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
      ),
      title: Text(
        server.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          _buildQualityBadge(server.quality),
          const SizedBox(width: 8),
          Text(
            server.type.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () => _selectServer(server),
    );
  }

  Widget _buildQualityBadge(String quality) {
    Color badgeColor;
    if (quality.contains('1080') || quality.contains('FHD')) {
      badgeColor = Colors.green;
    } else if (quality.contains('720') || quality.contains('HD')) {
      badgeColor = Colors.blue;
    } else if (quality.contains('480') || quality.contains('SD')) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        quality,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  IconData _getIconForServerType(String type) {
    switch (type.toLowerCase()) {
      case 'mp4':
        return Icons.video_file;
      case 'm3u8':
        return Icons.stream;
      case 'dash':
        return Icons.speed;
      default:
        return Icons.play_circle_outline;
    }
  }
}

/// Show server selection dialog
Future<StreamServer?> showServerSelectionDialog({
  required BuildContext context,
  required Map<String, List<StreamServer>> serversByExtension,
  required String contentId,
}) async {
  StreamServer? selectedServer;

  await showDialog(
    context: context,
    builder: (context) => ServerSelectionDialog(
      serversByExtension: serversByExtension,
      contentId: contentId,
      onServerSelected: (server) {
        selectedServer = server;
      },
    ),
  );

  return selectedServer;
}
