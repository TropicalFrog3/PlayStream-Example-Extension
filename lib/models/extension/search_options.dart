import 'media.dart';

/// Model representing search options for extension provider search operations
/// Matches the Kotlin SearchOptions data class structure
class SearchOptions {
  /// Metadata about the content being searched
  final Media media;

  /// Search query string (must be non-empty)
  final String query;

  /// Optional year filter for search results
  final int? year;

  SearchOptions({
    required this.media,
    required this.query,
    this.year,
  });

  factory SearchOptions.fromJson(Map<String, dynamic> json) {
    return SearchOptions(
      media: Media.fromJson(json['media'] as Map<String, dynamic>),
      query: json['query'] as String,
      year: json['year'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media': media.toJson(),
      'query': query,
      if (year != null) 'year': year,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchOptions &&
        other.media == media &&
        other.query == query &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(media, query, year);

  @override
  String toString() =>
      'SearchOptions(media: $media, query: $query, year: $year)';
}
