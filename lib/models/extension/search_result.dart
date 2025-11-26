/// Model representing a search result from an extension provider
/// Matches the Kotlin SearchResult data class structure
class SearchResult {
  /// Unique identifier for the content (used in findEpisodes)
  final String id;

  /// Display title of the movie/show
  final String title;

  /// URL to the content page on the provider's site
  final String url;

  SearchResult({
    required this.id,
    required this.title,
    required this.url,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.id == id &&
        other.title == title &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(id, title, url);

  @override
  String toString() => 'SearchResult(id: $id, title: $title, url: $url)';
}
