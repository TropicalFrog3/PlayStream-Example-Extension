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

  /// Optional media type filter: "movie" or "tv"
  final String? mediaType;

  /// Optional season number (for TV shows)
  final int? seasonNumber;

  SearchOptions({
    required this.media,
    required this.query,
    this.year,
    this.mediaType,
    this.seasonNumber,
  });

  factory SearchOptions.fromJson(Map<String, dynamic> json) {
    return SearchOptions(
      media: Media.fromJson(json['media'] as Map<String, dynamic>),
      query: json['query'] as String,
      year: json['year'] as int?,
      mediaType: json['mediaType'] as String?,
      seasonNumber: json['seasonNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media': media.toJson(),
      'query': query,
      if (year != null) 'year': year,
      if (mediaType != null) 'mediaType': mediaType,
      if (seasonNumber != null) 'seasonNumber': seasonNumber,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchOptions &&
        other.media == media &&
        other.query == query &&
        other.year == year &&
        other.mediaType == mediaType &&
        other.seasonNumber == seasonNumber;
  }

  @override
  int get hashCode =>
      Object.hash(media, query, year, mediaType, seasonNumber);

  @override
  String toString() =>
      'SearchOptions(media: $media, query: $query, year: $year, mediaType: $mediaType, seasonNumber: $seasonNumber)';
}
