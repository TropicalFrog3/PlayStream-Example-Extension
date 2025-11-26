import 'fuzzy_date.dart';

/// Model representing media metadata from external sources (TMDB/IMDB)
/// Matches the Kotlin Media data class structure
class Media {
  /// Internal identifier (non-negative)
  final int id;

  /// IMDB ID (e.g., "tt1234567")
  final String? imdbId;

  /// TMDB ID (e.g., "12345")
  final String? tmdbId;

  /// Release status (e.g., "Released", "Ongoing")
  final String? status;

  /// Media format (e.g., "MOVIE", "TV")
  final String? format;

  /// English title of the content
  final String? englishTitle;

  /// Total number of episodes (for TV shows)
  final int? episodeCount;

  /// Offset for absolute episode numbering
  final int? absoluteSeasonOffset;

  /// Alternative titles/names
  final List<String> synonyms;

  /// Whether content is adult-only
  final bool isAdult;

  /// Release/air date
  final FuzzyDate? startDate;

  Media({
    required this.id,
    this.imdbId,
    this.tmdbId,
    this.status,
    this.format,
    this.englishTitle,
    this.episodeCount,
    this.absoluteSeasonOffset,
    this.synonyms = const [],
    required this.isAdult,
    this.startDate,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int,
      imdbId: json['imdbId'] as String?,
      tmdbId: json['tmdbId'] as String?,
      status: json['status'] as String?,
      format: json['format'] as String?,
      englishTitle: json['englishTitle'] as String?,
      episodeCount: json['episodeCount'] as int?,
      absoluteSeasonOffset: json['absoluteSeasonOffset'] as int?,
      synonyms: (json['synonyms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isAdult: json['isAdult'] as bool,
      startDate: json['startDate'] != null
          ? FuzzyDate.fromJson(json['startDate'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (imdbId != null) 'imdbId': imdbId,
      if (tmdbId != null) 'tmdbId': tmdbId,
      if (status != null) 'status': status,
      if (format != null) 'format': format,
      if (englishTitle != null) 'englishTitle': englishTitle,
      if (episodeCount != null) 'episodeCount': episodeCount,
      if (absoluteSeasonOffset != null)
        'absoluteSeasonOffset': absoluteSeasonOffset,
      'synonyms': synonyms,
      'isAdult': isAdult,
      if (startDate != null) 'startDate': startDate!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Media && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Media(id: $id, tmdbId: $tmdbId, imdbId: $imdbId, englishTitle: $englishTitle)';
}
