import 'package:json_annotation/json_annotation.dart';
import 'trakt_movie.dart';
import 'trakt_show.dart';

part 'trakt_sync.g.dart';

@JsonSerializable()
class TraktSyncItems {
  final List<TraktMovie>? movies;
  final List<TraktShow>? shows;
  final List<TraktEpisode>? episodes;
  
  TraktSyncItems({
    this.movies,
    this.shows,
    this.episodes,
  });
  
  factory TraktSyncItems.fromJson(Map<String, dynamic> json) => _$TraktSyncItemsFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncItemsToJson(this);
}

@JsonSerializable()
class TraktSyncResponse {
  final TraktSyncAdded? added;
  final TraktSyncDeleted? deleted;
  final TraktSyncExisting? existing;
  final TraktSyncNotFound? not_found;
  
  TraktSyncResponse({
    this.added,
    this.deleted,
    this.existing,
    this.not_found,
  });
  
  factory TraktSyncResponse.fromJson(Map<String, dynamic> json) => _$TraktSyncResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncResponseToJson(this);
}

@JsonSerializable()
class TraktSyncAdded {
  final int? movies;
  final int? shows;
  final int? episodes;
  
  TraktSyncAdded({this.movies, this.shows, this.episodes});
  
  factory TraktSyncAdded.fromJson(Map<String, dynamic> json) => _$TraktSyncAddedFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncAddedToJson(this);
}

@JsonSerializable()
class TraktSyncDeleted {
  final int? movies;
  final int? shows;
  final int? episodes;
  
  TraktSyncDeleted({this.movies, this.shows, this.episodes});
  
  factory TraktSyncDeleted.fromJson(Map<String, dynamic> json) => _$TraktSyncDeletedFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncDeletedToJson(this);
}

@JsonSerializable()
class TraktSyncExisting {
  final int? movies;
  final int? shows;
  final int? episodes;
  
  TraktSyncExisting({this.movies, this.shows, this.episodes});
  
  factory TraktSyncExisting.fromJson(Map<String, dynamic> json) => _$TraktSyncExistingFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncExistingToJson(this);
}

@JsonSerializable()
class TraktSyncNotFound {
  final List<TraktMovie>? movies;
  final List<TraktShow>? shows;
  final List<TraktEpisode>? episodes;
  
  TraktSyncNotFound({this.movies, this.shows, this.episodes});
  
  factory TraktSyncNotFound.fromJson(Map<String, dynamic> json) => _$TraktSyncNotFoundFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSyncNotFoundToJson(this);
}

@JsonSerializable()
class TraktEpisode {
  final TraktIds? ids;
  
  TraktEpisode({this.ids});
  
  factory TraktEpisode.fromJson(Map<String, dynamic> json) => _$TraktEpisodeFromJson(json);
  Map<String, dynamic> toJson() => _$TraktEpisodeToJson(this);
}

@JsonSerializable()
class TraktMediaItem {
  @JsonKey(name: 'watched_at')
  final String? watchedAt;
  final String? action;
  final String? type;
  final TraktMovie? movie;
  final TraktShow? show;
  final TraktEpisode? episode;
  
  TraktMediaItem({
    this.watchedAt,
    this.action,
    this.type,
    this.movie,
    this.show,
    this.episode,
  });
  
  factory TraktMediaItem.fromJson(Map<String, dynamic> json) => _$TraktMediaItemFromJson(json);
  Map<String, dynamic> toJson() => _$TraktMediaItemToJson(this);
}

enum TraktListType {
  @JsonValue('watched')
  watched('watched'),
  @JsonValue('collection')
  collection('collection'),
  @JsonValue('watchlist')
  watchlist('watchlist'),
  @JsonValue('ratings')
  ratings('ratings');
  
  final String value;
  const TraktListType(this.value);
}

enum TraktListMediaType {
  @JsonValue('movies')
  movies('movies'),
  @JsonValue('shows')
  shows('shows'),
  @JsonValue('seasons')
  seasons('seasons'),
  @JsonValue('episodes')
  episodes('episodes');
  
  final String value;
  const TraktListMediaType(this.value);
}
