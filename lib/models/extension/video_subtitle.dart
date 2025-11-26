/// Model representing a video subtitle track from an extension provider
/// Matches the Kotlin VideoSubtitle data class structure
class VideoSubtitle {
  /// Unique identifier for the subtitle track
  final String id;

  /// URL to the subtitle file (VTT, SRT, etc.)
  final String url;

  /// Language code (e.g., "en", "es", "fr")
  final String language;

  /// Whether this subtitle should be selected by default
  final bool isDefault;

  VideoSubtitle({
    required this.id,
    required this.url,
    required this.language,
    required this.isDefault,
  });

  factory VideoSubtitle.fromJson(Map<String, dynamic> json) {
    return VideoSubtitle(
      id: json['id'] as String,
      url: json['url'] as String,
      language: json['language'] as String,
      isDefault: json['isDefault'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'language': language,
      'isDefault': isDefault,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoSubtitle &&
        other.id == id &&
        other.url == url &&
        other.language == language &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode => Object.hash(id, url, language, isDefault);

  @override
  String toString() =>
      'VideoSubtitle(id: $id, url: $url, language: $language, isDefault: $isDefault)';
}
