/// Model representing episode details from an extension provider
/// Matches the Kotlin EpisodeDetails data class structure
class EpisodeDetails {
  /// Unique identifier for the episode (used in findEpisodeServer)
  final String id;

  /// Episode number (must be positive, starting from 1)
  final int number;

  /// URL to the episode page
  final String url;

  /// Optional episode title
  final String? title;

  EpisodeDetails({
    required this.id,
    required this.number,
    required this.url,
    this.title,
  });

  factory EpisodeDetails.fromJson(Map<String, dynamic> json) {
    return EpisodeDetails(
      id: json['id'] as String,
      number: json['number'] as int,
      url: json['url'] as String,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'url': url,
      if (title != null) 'title': title,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodeDetails &&
        other.id == id &&
        other.number == number &&
        other.url == url &&
        other.title == title;
  }

  @override
  int get hashCode => Object.hash(id, number, url, title);

  @override
  String toString() =>
      'EpisodeDetails(id: $id, number: $number, url: $url, title: $title)';
}
