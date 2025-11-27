import 'video_source.dart';
import 'video_subtitle.dart';

/// Model representing streaming sources for a movie
/// Contains all available video qualities and subtitles for direct playback
class MovieStreamSource {
  /// Provider's movie identifier
  final String movieId;

  /// List of available video sources (different qualities/servers)
  final List<VideoSource> videoSources;

  /// List of available subtitles
  final List<VideoSubtitle> subtitles;

  MovieStreamSource({
    required this.movieId,
    required this.videoSources,
    this.subtitles = const [],
  });

  factory MovieStreamSource.fromJson(Map<String, dynamic> json) {
    return MovieStreamSource(
      movieId: json['movieId'] as String,
      videoSources: (json['videoSources'] as List<dynamic>)
          .map((e) => VideoSource.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => VideoSubtitle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'videoSources': videoSources.map((v) => v.toJson()).toList(),
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovieStreamSource && other.movieId == movieId;
  }

  @override
  int get hashCode => movieId.hashCode;

  @override
  String toString() =>
      'MovieStreamSource(movieId: $movieId, sources: ${videoSources.length}, subtitles: ${subtitles.length})';
}
