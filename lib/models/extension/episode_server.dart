import 'video_source.dart';

/// Model representing an episode server from an extension provider
/// Matches the Kotlin EpisodeServer data class structure
class EpisodeServer {
  /// Server name/identifier (e.g., "vidking", "streamtape")
  final String server;

  /// HTTP headers required for playback (e.g., Referer, User-Agent)
  final Map<String, String> headers;

  /// List of available video sources (must have at least one)
  final List<VideoSource> videoSources;

  EpisodeServer({
    required this.server,
    this.headers = const {},
    required this.videoSources,
  });

  factory EpisodeServer.fromJson(Map<String, dynamic> json) {
    return EpisodeServer(
      server: json['server'] as String,
      headers: json['headers'] != null
          ? Map<String, String>.from(json['headers'] as Map)
          : {},
      videoSources: (json['videoSources'] as List<dynamic>)
          .map((e) => VideoSource.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'headers': headers,
      'videoSources': videoSources.map((v) => v.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeServer && other.server == server;
  }

  @override
  int get hashCode => server.hashCode;

  @override
  String toString() =>
      'EpisodeServer(server: $server, headers: $headers, videoSources: ${videoSources.length})';
}
