/// Model representing an episode within a TV show season
/// Different from anime EpisodeDetails which uses absolute numbering
class ShowEpisodeDetails {
  /// Provider's unique identifier for this episode
  final String id;

  /// Season number (1, 2, 3, etc.)
  final int seasonNumber;

  /// Episode number within the season (1, 2, 3, etc.)
  final int episodeNumber;

  /// URL to the episode page on the provider's site
  final String url;

  /// Optional episode title
  final String? title;

  /// Optional episode thumbnail/poster URL
  final String? thumbnail;

  ShowEpisodeDetails({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.url,
    this.title,
    this.thumbnail,
  });

  factory ShowEpisodeDetails.fromJson(Map<String, dynamic> json) {
    return ShowEpisodeDetails(
      id: json['id'] as String,
      seasonNumber: json['seasonNumber'] as int,
      episodeNumber: json['episodeNumber'] as int,
      url: json['url'] as String,
      title: json['title'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'url': url,
      if (title != null) 'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShowEpisodeDetails &&
        other.id == id &&
        other.seasonNumber == seasonNumber &&
        other.episodeNumber == episodeNumber &&
        other.url == url &&
        other.title == title &&
        other.thumbnail == thumbnail;
  }

  @override
  int get hashCode =>
      Object.hash(id, seasonNumber, episodeNumber, url, title, thumbnail);

  @override
  String toString() =>
      'ShowEpisodeDetails(id: $id, S${seasonNumber}E${episodeNumber}, title: $title)';
}
