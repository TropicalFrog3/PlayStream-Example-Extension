import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../models/extension/stream_server.dart';

enum PlayerState {
  idle,
  loading,
  playing,
  paused,
  buffering,
  error,
}

class CustomVideoPlayerController extends ChangeNotifier {
  PlayerState _state = PlayerState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
  bool _isFullscreen = false;
  String? _errorMessage;
  StreamServer? _currentServer;
  List<StreamServer>? _fallbackServers;
  int _currentServerIndex = 0;
  
  Timer? _progressTimer;
  final Logger _logger = Logger();
  
  PlayerState get state => _state;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  bool get isFullscreen => _isFullscreen;
  String? get errorMessage => _errorMessage;
  StreamServer? get currentServer => _currentServer;
  
  bool get isPlaying => _state == PlayerState.playing;
  bool get isPaused => _state == PlayerState.paused;
  bool get isBuffering => _state == PlayerState.buffering;
  bool get hasError => _state == PlayerState.error;
  bool get hasFallbackServers => _fallbackServers != null && _fallbackServers!.isNotEmpty;
  
  /// Initialize player with a StreamServer
  Future<void> initializeWithServer(
    StreamServer server, {
    List<StreamServer>? fallbackServers,
  }) async {
    _currentServer = server;
    _fallbackServers = fallbackServers;
    _currentServerIndex = 0;
    
    await _initializeServer(server);
  }
  
  /// Initialize player with a specific server
  Future<void> _initializeServer(StreamServer server) async {
    try {
      _state = PlayerState.loading;
      _errorMessage = null;
      notifyListeners();
      
      _logger.i('Initializing video player with server: ${server.name}');
      _logger.d('URL: ${server.url}');
      _logger.d('Type: ${server.type}');
      _logger.d('Quality: ${server.quality}');
      
      if (server.headers != null && server.headers!.isNotEmpty) {
        _logger.d('Headers: ${server.headers}');
      }
      
      // TODO: Implement actual video initialization with headers
      // This is a placeholder for the custom video player implementation
      // The actual implementation should:
      // 1. Use the server.url as the video source
      // 2. Apply server.headers if provided
      // 3. Handle different server.type (mp4, m3u8, dash)
      
      await Future.delayed(const Duration(seconds: 1));
      
      _duration = const Duration(minutes: 90); // Placeholder
      _state = PlayerState.paused;
      _currentServer = server;
      notifyListeners();
      
      _logger.i('Video player initialized successfully');
    } catch (e, stackTrace) {
      _logger.e('Error initializing video player', error: e, stackTrace: stackTrace);
      _errorMessage = e.toString();
      _state = PlayerState.error;
      notifyListeners();
      
      // Try fallback server if available
      await _tryFallbackServer();
    }
  }
  
  /// Try to use a fallback server when the current server fails
  Future<void> _tryFallbackServer() async {
    if (_fallbackServers == null || _fallbackServers!.isEmpty) {
      _logger.w('No fallback servers available');
      return;
    }
    
    _currentServerIndex++;
    
    if (_currentServerIndex >= _fallbackServers!.length) {
      _logger.e('All fallback servers exhausted');
      _errorMessage = 'All servers failed. Please try again later.';
      _state = PlayerState.error;
      notifyListeners();
      return;
    }
    
    final fallbackServer = _fallbackServers![_currentServerIndex];
    _logger.i('Trying fallback server ${_currentServerIndex + 1}/${_fallbackServers!.length}: ${fallbackServer.name}');
    
    await _initializeServer(fallbackServer);
  }
  
  /// Switch to a different server
  Future<void> switchServer(StreamServer server) async {
    _logger.i('Switching to server: ${server.name}');
    
    // Save current position
    final currentPosition = _position;
    
    // Initialize with new server
    await _initializeServer(server);
    
    // Restore position if initialization was successful
    if (_state != PlayerState.error && currentPosition > Duration.zero) {
      await seekTo(currentPosition);
    }
  }
  
  /// Retry with current server
  Future<void> retry() async {
    if (_currentServer != null) {
      _logger.i('Retrying with current server');
      await _initializeServer(_currentServer!);
    }
  }
  
  /// Legacy method for backward compatibility
  Future<void> initialize(String videoUrl) async {
    // Create a basic StreamServer from URL
    final server = StreamServer(
      id: 'legacy',
      name: 'Direct URL',
      quality: 'Unknown',
      type: _detectVideoType(videoUrl),
      url: videoUrl,
    );
    
    await initializeWithServer(server);
  }
  
  /// Detect video type from URL
  String _detectVideoType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.mp4')) return 'mp4';
    if (lowerUrl.endsWith('.m3u8') || lowerUrl.contains('m3u8')) return 'm3u8';
    if (lowerUrl.contains('dash') || lowerUrl.endsWith('.mpd')) return 'dash';
    return 'unknown';
  }
  
  Future<void> play() async {
    if (_state == PlayerState.error) return;
    
    _state = PlayerState.playing;
    notifyListeners();
    
    _startProgressTimer();
  }
  
  Future<void> pause() async {
    if (_state == PlayerState.error) return;
    
    _state = PlayerState.paused;
    notifyListeners();
    
    _stopProgressTimer();
  }
  
  Future<void> seekTo(Duration position) async {
    if (_state == PlayerState.error) return;
    
    _position = position;
    notifyListeners();
  }
  
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    notifyListeners();
  }
  
  Future<void> toggleFullscreen() async {
    _isFullscreen = !_isFullscreen;
    
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    
    notifyListeners();
  }
  
  void _startProgressTimer() {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_state == PlayerState.playing) {
        _position += const Duration(milliseconds: 100);
        if (_position >= _duration) {
          _position = _duration;
          pause();
        }
        notifyListeners();
      }
    });
  }
  
  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }
  
  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }
}
