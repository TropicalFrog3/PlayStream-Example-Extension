import 'video_subtitle.dart';

/// Model representing a video source from an extension provider
/// Matches the Kotlin VideoSource data class structure
class VideoSource {
  /// Streaming URL (HLS m3u8 or direct MP4)
  final String url;

  /// Stream type: "mp4" or "m3u8"
  final String type;

  /// Quality label (e.g., "1080p", "720p", "auto")
  final String quality;

  /// List of available subtitles (can be empty)
  final List<VideoSubtitle> subtitles;

  VideoSource({
    required this.url,
    required this.type,
    required this.quality,
    this.subtitles = const [],
  });

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      url: json['url'] as String,
      type: json['type'] as String,
      quality: json['quality'] as String,
      subtitles: (json['subtitles'] as List<dynamic>?)
              ?.map((e) => VideoSubtitle.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'quality': quality,
      'subtitles': subtitles.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoSource &&
        other.url == url &&
        other.type == type &&
        other.quality == quality;
  }

  @override
  int get hashCode => Object.hash(url, type, quality);

  @override
  String toString() =>
      'VideoSource(url: $url, type: $type, quality: $quality, subtitles: ${subtitles.length})';
}
