import 'stream_server.dart';

/// Model representing detailed information about a movie from an extension
class MovieDetails {
  final String id;
  final String title;
  final String? description;
  final String? posterUrl;
  final String? backdropUrl;
  final int? year;
  final List<StreamServer> servers;

  MovieDetails({
    required this.id,
    required this.title,
    this.description,
    this.posterUrl,
    this.backdropUrl,
    this.year,
    required this.servers,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      posterUrl: json['posterUrl'] as String?,
      backdropUrl: json['backdropUrl'] as String?,
      year: json['year'] as int?,
      servers: (json['servers'] as List<dynamic>?)
              ?.map((e) => StreamServer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'year': year,
      'servers': servers.map((s) => s.toJson()).toList(),
    };
  }
}
