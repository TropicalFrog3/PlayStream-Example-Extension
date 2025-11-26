import 'package:json_annotation/json_annotation.dart';

part 'trakt_movie.g.dart';

@JsonSerializable()
class TraktMovie {
  final String? title;
  final int? year;
  final TraktIds? ids;
  final String? tagline;
  final String? overview;
  final String? released;
  final int? runtime;
  final String? country;
  final String? trailer;
  final String? homepage;
  final String? status;
  final double? rating;
  final int? votes;
  final String? language;
  final List<String>? genres;
  final TraktImages? images;
  
  TraktMovie({
    this.title,
    this.year,
    this.ids,
    this.tagline,
    this.overview,
    this.released,
    this.runtime,
    this.country,
    this.trailer,
    this.homepage,
    this.status,
    this.rating,
    this.votes,
    this.language,
    this.genres,
    this.images,
  });
  
  factory TraktMovie.fromJson(Map<String, dynamic> json) => _$TraktMovieFromJson(json);
  Map<String, dynamic> toJson() => _$TraktMovieToJson(this);
}

@JsonSerializable()
class TraktImages {
  final List<String>? fanart;
  final List<String>? poster;
  final List<String>? logo;
  final List<String>? clearart;
  final List<String>? banner;
  final List<String>? thumb;
  
  TraktImages({
    this.fanart,
    this.poster,
    this.logo,
    this.clearart,
    this.banner,
    this.thumb,
  });
  
  factory TraktImages.fromJson(Map<String, dynamic> json) => _$TraktImagesFromJson(json);
  Map<String, dynamic> toJson() => _$TraktImagesToJson(this);
}

@JsonSerializable()
class TraktIds {
  final int? trakt;
  final String? slug;
  final String? imdb;
  final int? tmdb;
  
  TraktIds({
    this.trakt,
    this.slug,
    this.imdb,
    this.tmdb,
  });
  
  factory TraktIds.fromJson(Map<String, dynamic> json) => _$TraktIdsFromJson(json);
  Map<String, dynamic> toJson() => _$TraktIdsToJson(this);
}

@JsonSerializable()
class TraktTrendingMovie {
  final int? watchers;
  final TraktMovie? movie;
  
  TraktTrendingMovie({
    this.watchers,
    this.movie,
  });
  
  factory TraktTrendingMovie.fromJson(Map<String, dynamic> json) => _$TraktTrendingMovieFromJson(json);
  Map<String, dynamic> toJson() => _$TraktTrendingMovieToJson(this);
}

@JsonSerializable()
class TraktAnticipatedMovie {
  @JsonKey(name: 'list_count')
  final int? listCount;
  final TraktMovie? movie;
  
  TraktAnticipatedMovie({
    this.listCount,
    this.movie,
  });
  
  factory TraktAnticipatedMovie.fromJson(Map<String, dynamic> json) => _$TraktAnticipatedMovieFromJson(json);
  Map<String, dynamic> toJson() => _$TraktAnticipatedMovieToJson(this);
}
