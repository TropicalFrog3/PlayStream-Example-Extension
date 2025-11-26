// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_movie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktMovie _$TraktMovieFromJson(Map<String, dynamic> json) => TraktMovie(
      title: json['title'] as String?,
      year: (json['year'] as num?)?.toInt(),
      ids: json['ids'] == null
          ? null
          : TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
      tagline: json['tagline'] as String?,
      overview: json['overview'] as String?,
      released: json['released'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      country: json['country'] as String?,
      trailer: json['trailer'] as String?,
      homepage: json['homepage'] as String?,
      status: json['status'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      votes: (json['votes'] as num?)?.toInt(),
      language: json['language'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      images: json['images'] == null
          ? null
          : TraktImages.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktMovieToJson(TraktMovie instance) =>
    <String, dynamic>{
      'title': instance.title,
      'year': instance.year,
      'ids': instance.ids,
      'tagline': instance.tagline,
      'overview': instance.overview,
      'released': instance.released,
      'runtime': instance.runtime,
      'country': instance.country,
      'trailer': instance.trailer,
      'homepage': instance.homepage,
      'status': instance.status,
      'rating': instance.rating,
      'votes': instance.votes,
      'language': instance.language,
      'genres': instance.genres,
      'images': instance.images,
    };

TraktImages _$TraktImagesFromJson(Map<String, dynamic> json) => TraktImages(
      fanart:
          (json['fanart'] as List<dynamic>?)?.map((e) => e as String).toList(),
      poster:
          (json['poster'] as List<dynamic>?)?.map((e) => e as String).toList(),
      logo: (json['logo'] as List<dynamic>?)?.map((e) => e as String).toList(),
      clearart: (json['clearart'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      banner:
          (json['banner'] as List<dynamic>?)?.map((e) => e as String).toList(),
      thumb:
          (json['thumb'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TraktImagesToJson(TraktImages instance) =>
    <String, dynamic>{
      'fanart': instance.fanart,
      'poster': instance.poster,
      'logo': instance.logo,
      'clearart': instance.clearart,
      'banner': instance.banner,
      'thumb': instance.thumb,
    };

TraktIds _$TraktIdsFromJson(Map<String, dynamic> json) => TraktIds(
      trakt: (json['trakt'] as num?)?.toInt(),
      slug: json['slug'] as String?,
      imdb: json['imdb'] as String?,
      tmdb: (json['tmdb'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TraktIdsToJson(TraktIds instance) => <String, dynamic>{
      'trakt': instance.trakt,
      'slug': instance.slug,
      'imdb': instance.imdb,
      'tmdb': instance.tmdb,
    };

TraktTrendingMovie _$TraktTrendingMovieFromJson(Map<String, dynamic> json) =>
    TraktTrendingMovie(
      watchers: (json['watchers'] as num?)?.toInt(),
      movie: json['movie'] == null
          ? null
          : TraktMovie.fromJson(json['movie'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktTrendingMovieToJson(TraktTrendingMovie instance) =>
    <String, dynamic>{
      'watchers': instance.watchers,
      'movie': instance.movie,
    };

TraktAnticipatedMovie _$TraktAnticipatedMovieFromJson(
        Map<String, dynamic> json) =>
    TraktAnticipatedMovie(
      listCount: (json['list_count'] as num?)?.toInt(),
      movie: json['movie'] == null
          ? null
          : TraktMovie.fromJson(json['movie'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktAnticipatedMovieToJson(
        TraktAnticipatedMovie instance) =>
    <String, dynamic>{
      'list_count': instance.listCount,
      'movie': instance.movie,
    };
