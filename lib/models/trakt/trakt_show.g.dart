// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_show.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktShow _$TraktShowFromJson(Map<String, dynamic> json) => TraktShow(
      title: json['title'] as String?,
      year: (json['year'] as num?)?.toInt(),
      ids: json['ids'] == null
          ? null
          : TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
      overview: json['overview'] as String?,
      firstAired: json['first_aired'] as String?,
      runtime: (json['runtime'] as num?)?.toInt(),
      certification: json['certification'] as String?,
      network: json['network'] as String?,
      country: json['country'] as String?,
      trailer: json['trailer'] as String?,
      homepage: json['homepage'] as String?,
      status: json['status'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      votes: (json['votes'] as num?)?.toInt(),
      language: json['language'] as String?,
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList(),
      airedEpisodes: (json['aired_episodes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TraktShowToJson(TraktShow instance) => <String, dynamic>{
      'title': instance.title,
      'year': instance.year,
      'ids': instance.ids,
      'overview': instance.overview,
      'first_aired': instance.firstAired,
      'runtime': instance.runtime,
      'certification': instance.certification,
      'network': instance.network,
      'country': instance.country,
      'trailer': instance.trailer,
      'homepage': instance.homepage,
      'status': instance.status,
      'rating': instance.rating,
      'votes': instance.votes,
      'language': instance.language,
      'genres': instance.genres,
      'aired_episodes': instance.airedEpisodes,
    };
