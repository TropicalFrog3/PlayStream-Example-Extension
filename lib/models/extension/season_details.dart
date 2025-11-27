/// Model representing a season of a TV show from an extension provider
/// Used for hierarchical TV show navigation (Show → Seasons → Episodes)
class SeasonDetails {
  /// Provider's unique identifier for this season
  final String id;

  /// Season number (1, 2, 3, etc.)
  final int seasonNumber;

  /// Optional season title (e.g., "Season 1", "The Beginning")
  final String? title;

  /// Number of episodes in this season
  final int episodeCount;

  /// URL to the season page on the provider's site
  final String url;

  SeasonDetails({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
    required this.url,
    this.title,
  });

  factory SeasonDetails.fromJson(Map<String, dynamic> json) {
    return SeasonDetails(
      id: json['id'] as String,
      seasonNumber: json['seasonNumber'] as int,
      episodeCount: json['episodeCount'] as int,
      url: json['url'] as String,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonNumber': seasonNumber,
      'episodeCount': episodeCount,
      'url': url,
      if (title != null) 'title': title,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonDetails &&
        other.id == id &&
        other.seasonNumber == seasonNumber &&
        other.episodeCount == episodeCount &&
        other.url == url &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, seasonNumber, episodeCount, url, title);

  @override
  String toString() =>
      'SeasonDetails(id: $id, seasonNumber: $seasonNumber, episodeCount: $episodeCount, title: $title)';
}
