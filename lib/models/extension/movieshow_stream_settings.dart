/// Settings and capabilities for a movie/show streaming provider extension
class MovieShowStreamSettings {
  /// List of available streaming servers
  final List<String> streamServers;

  /// Whether this provider supports movies
  final bool supportsMovies;

  /// Whether this provider supports TV shows
  final bool supportsTVShows;

  /// Whether this provider supports dubbed content
  final bool supportsDub;

  MovieShowStreamSettings({
    required this.streamServers,
    required this.supportsMovies,
    required this.supportsTVShows,
    this.supportsDub = false,
  });

  factory MovieShowStreamSettings.fromJson(Map<String, dynamic> json) {
    return MovieShowStreamSettings(
      streamServers: (json['streamServers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      supportsMovies: json['supportsMovies'] as bool,
      supportsTVShows: json['supportsTVShows'] as bool,
      supportsDub: json['supportsDub'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamServers': streamServers,
      'supportsMovies': supportsMovies,
      'supportsTVShows': supportsTVShows,
      'supportsDub': supportsDub,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MovieShowStreamSettings &&
        other.supportsMovies == supportsMovies &&
        other.supportsTVShows == supportsTVShows &&
        other.supportsDub == supportsDub;
  }

  @override
  int get hashCode =>
      Object.hash(supportsMovies, supportsTVShows, supportsDub);

  @override
  String toString() =>
      'MovieShowStreamSettings(servers: ${streamServers.length}, movies: $supportsMovies, tv: $supportsTVShows, dub: $supportsDub)';
}
