import 'package:flutter/material.dart';
import '../../services/video/video_player_controller.dart';
import '../../models/extension/stream_server.dart';
import '../widgets/server_selection_dialog.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String? videoUrl;
  final StreamServer? server;
  final List<StreamServer>? availableServers;
  final String? contentId;
  
  const PlayerScreen({
    super.key,
    required this.title,
    this.videoUrl,
    this.server,
    this.availableServers,
    this.contentId,
  }) : assert(
         videoUrl != null || server != null,
         'Either videoUrl or server must be provided',
       );

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late CustomVideoPlayerController _controller;
  bool _showControls = true;
  
  @override
  void initState() {
    super.initState();
    _controller = CustomVideoPlayerController();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    if (widget.server != null) {
      // Initialize with StreamServer
      await _controller.initializeWithServer(
        widget.server!,
        fallbackServers: widget.availableServers,
      );
    } else if (widget.videoUrl != null) {
      // Legacy: Initialize with URL
      await _controller.initialize(widget.videoUrl!);
    }
  }
  
  Future<void> _showServerSelection() async {
    if (widget.availableServers == null || widget.availableServers!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No alternative servers available')),
      );
      return;
    }
    
    // Group servers by extension
    final serversByExtension = <String, List<StreamServer>>{};
    for (final server in widget.availableServers!) {
      // Extract extension ID from server metadata or use a default
      final extensionId = 'Extension'; // This should come from server metadata
      serversByExtension.putIfAbsent(extensionId, () => []).add(server);
    }
    
    final selectedServer = await showServerSelectionDialog(
      context: context,
      serversByExtension: serversByExtension,
      contentId: widget.contentId ?? widget.title,
    );
    
    if (selectedServer != null) {
      await _controller.switchServer(selectedServer);
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video player area
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (_controller.hasError) {
                        return Center(
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
                                'Error: ${_controller.errorMessage}',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _controller.retry(),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                  ),
                                  if (_controller.hasFallbackServers) ...[
                                    const SizedBox(width: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showServerSelection,
                                      icon: const Icon(Icons.dns),
                                      label: const Text('Try Another Server'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (_controller.state == PlayerState.loading) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              if (_controller.currentServer != null)
                                Text(
                                  'Loading ${_controller.currentServer!.name}...',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        );
                      }
                      
                      // Placeholder for actual video rendering
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.movie,
                              size: 100,
                              color: Colors.white54,
                            ),
                            if (_controller.currentServer != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _controller.currentServer!.name,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _controller.currentServer!.quality,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Controls overlay
            if (_showControls)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showControls = !_showControls;
                  });
                },
                child: Container(
                  color: Colors.black54,
                  child: Column(
                    children: [
                      // Top bar
                      AppBar(
                        backgroundColor: Colors.transparent,
                        title: Text(widget.title),
                      ),
                      
                      const Spacer(),
                      
                      // Play/Pause button
                      ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) {
                          return IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _controller.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (_controller.isPlaying) {
                                _controller.pause();
                              } else {
                                _controller.play();
                              }
                            },
                          );
                        },
                      ),
                      
                      const Spacer(),
                      
                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            ListenableBuilder(
                              listenable: _controller,
                              builder: (context, _) {
                                return Row(
                                  children: [
                                    Text(
                                      _formatDuration(_controller.position),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _controller.duration.inMilliseconds > 0
                                            ? _controller.position.inMilliseconds /
                                                _controller.duration.inMilliseconds
                                            : 0,
                                        onChanged: (value) {
                                          final position = Duration(
                                            milliseconds: (value *
                                                    _controller.duration.inMilliseconds)
                                                .round(),
                                          );
                                          _controller.seekTo(position);
                                        },
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_controller.duration),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                );
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_10, color: Colors.white),
                                  onPressed: () {
                                    final newPosition = _controller.position -
                                        const Duration(seconds: 10);
                                    _controller.seekTo(
                                      newPosition < Duration.zero
                                          ? Duration.zero
                                          : newPosition,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10, color: Colors.white),
                                  onPressed: () {
                                    final newPosition = _controller.position +
                                        const Duration(seconds: 10);
                                    _controller.seekTo(
                                      newPosition > _controller.duration
                                          ? _controller.duration
                                          : newPosition,
                                    );
                                  },
                                ),
                                // Server selection button
                                if (widget.availableServers != null && 
                                    widget.availableServers!.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.dns, color: Colors.white),
                                    tooltip: 'Select Server',
                                    onPressed: _showServerSelection,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                                  onPressed: () {
                                    _controller.toggleFullscreen();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
