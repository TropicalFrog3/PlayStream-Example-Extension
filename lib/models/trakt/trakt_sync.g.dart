// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_sync.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktSyncItems _$TraktSyncItemsFromJson(Map<String, dynamic> json) =>
    TraktSyncItems(
      movies: (json['movies'] as List<dynamic>?)
          ?.map((e) => TraktMovie.fromJson(e as Map<String, dynamic>))
          .toList(),
      shows: (json['shows'] as List<dynamic>?)
          ?.map((e) => TraktShow.fromJson(e as Map<String, dynamic>))
          .toList(),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => TraktEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TraktSyncItemsToJson(TraktSyncItems instance) =>
    <String, dynamic>{
      'movies': instance.movies,
      'shows': instance.shows,
      'episodes': instance.episodes,
    };

TraktSyncResponse _$TraktSyncResponseFromJson(Map<String, dynamic> json) =>
    TraktSyncResponse(
      added: json['added'] == null
          ? null
          : TraktSyncAdded.fromJson(json['added'] as Map<String, dynamic>),
      deleted: json['deleted'] == null
          ? null
          : TraktSyncDeleted.fromJson(json['deleted'] as Map<String, dynamic>),
      existing: json['existing'] == null
          ? null
          : TraktSyncExisting.fromJson(
              json['existing'] as Map<String, dynamic>),
      not_found: json['not_found'] == null
          ? null
          : TraktSyncNotFound.fromJson(
              json['not_found'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktSyncResponseToJson(TraktSyncResponse instance) =>
    <String, dynamic>{
      'added': instance.added,
      'deleted': instance.deleted,
      'existing': instance.existing,
      'not_found': instance.not_found,
    };

TraktSyncAdded _$TraktSyncAddedFromJson(Map<String, dynamic> json) =>
    TraktSyncAdded(
      movies: (json['movies'] as num?)?.toInt(),
      shows: (json['shows'] as num?)?.toInt(),
      episodes: (json['episodes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TraktSyncAddedToJson(TraktSyncAdded instance) =>
    <String, dynamic>{
      'movies': instance.movies,
      'shows': instance.shows,
      'episodes': instance.episodes,
    };

TraktSyncDeleted _$TraktSyncDeletedFromJson(Map<String, dynamic> json) =>
    TraktSyncDeleted(
      movies: (json['movies'] as num?)?.toInt(),
      shows: (json['shows'] as num?)?.toInt(),
      episodes: (json['episodes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TraktSyncDeletedToJson(TraktSyncDeleted instance) =>
    <String, dynamic>{
      'movies': instance.movies,
      'shows': instance.shows,
      'episodes': instance.episodes,
    };

TraktSyncExisting _$TraktSyncExistingFromJson(Map<String, dynamic> json) =>
    TraktSyncExisting(
      movies: (json['movies'] as num?)?.toInt(),
      shows: (json['shows'] as num?)?.toInt(),
      episodes: (json['episodes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TraktSyncExistingToJson(TraktSyncExisting instance) =>
    <String, dynamic>{
      'movies': instance.movies,
      'shows': instance.shows,
      'episodes': instance.episodes,
    };

TraktSyncNotFound _$TraktSyncNotFoundFromJson(Map<String, dynamic> json) =>
    TraktSyncNotFound(
      movies: (json['movies'] as List<dynamic>?)
          ?.map((e) => TraktMovie.fromJson(e as Map<String, dynamic>))
          .toList(),
      shows: (json['shows'] as List<dynamic>?)
          ?.map((e) => TraktShow.fromJson(e as Map<String, dynamic>))
          .toList(),
      episodes: (json['episodes'] as List<dynamic>?)
          ?.map((e) => TraktEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TraktSyncNotFoundToJson(TraktSyncNotFound instance) =>
    <String, dynamic>{
      'movies': instance.movies,
      'shows': instance.shows,
      'episodes': instance.episodes,
    };

TraktEpisode _$TraktEpisodeFromJson(Map<String, dynamic> json) => TraktEpisode(
      ids: json['ids'] == null
          ? null
          : TraktIds.fromJson(json['ids'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktEpisodeToJson(TraktEpisode instance) =>
    <String, dynamic>{
      'ids': instance.ids,
    };

TraktMediaItem _$TraktMediaItemFromJson(Map<String, dynamic> json) =>
    TraktMediaItem(
      watchedAt: json['watched_at'] as String?,
      action: json['action'] as String?,
      type: json['type'] as String?,
      movie: json['movie'] == null
          ? null
          : TraktMovie.fromJson(json['movie'] as Map<String, dynamic>),
      show: json['show'] == null
          ? null
          : TraktShow.fromJson(json['show'] as Map<String, dynamic>),
      episode: json['episode'] == null
          ? null
          : TraktEpisode.fromJson(json['episode'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktMediaItemToJson(TraktMediaItem instance) =>
    <String, dynamic>{
      'watched_at': instance.watchedAt,
      'action': instance.action,
      'type': instance.type,
      'movie': instance.movie,
      'show': instance.show,
      'episode': instance.episode,
    };
