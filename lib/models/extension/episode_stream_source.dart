import 'video_source.dart';
import 'video_subtitle.dart';

/// Model representing streaming sources for a TV show episode
/// Contains all available video qualities and subtitles for the specific episode
class EpisodeStreamSource {
  /// Season number
  final int seasonNumber;

  /// Episode number within the season
  final int episodeNumber;

  /// List of available video sources (different qualities/servers)
  final List<VideoSource> videoSources;

  /// List of available subtitles
  final List<VideoSubtitle> subtitles;

  EpisodeStreamSource({
    required this.seasonNumber,
    required this.episodeNumber,
    required this.videoSources,
    this.subtitles = const [],
  });

  factory EpisodeStreamSource.fromJson(Map<String, dynamic> json) {
    return EpisodeStreamSource(
      seasonNumber: json['seasonNumber'] as int,
      episodeNumber: json['episodeNumber'] as int,
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
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'videoSources': videoSources.map((v) => v.toJson()).toList(),
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeStreamSource &&
        other.seasonNumber == seasonNumber &&
        other.episodeNumber == episodeNumber;
  }

  @override
  int get hashCode => Object.hash(seasonNumber, episodeNumber);

  @override
  String toString() =>
      'EpisodeStreamSource(S${seasonNumber}E${episodeNumber}, sources: ${videoSources.length}, subtitles: ${subtitles.length})';
}
