import 'package:json_annotation/json_annotation.dart';
import 'trakt_movie.dart';

part 'trakt_show.g.dart';

@JsonSerializable()
class TraktShow {
  final String? title;
  final int? year;
  final TraktIds? ids;
  final String? overview;
  @JsonKey(name: 'first_aired')
  final String? firstAired;
  final int? runtime;
  final String? certification;
  final String? network;
  final String? country;
  final String? trailer;
  final String? homepage;
  final String? status;
  final double? rating;
  final int? votes;
  final String? language;
  final List<String>? genres;
  @JsonKey(name: 'aired_episodes')
  final int? airedEpisodes;
  
  TraktShow({
    this.title,
    this.year,
    this.ids,
    this.overview,
    this.firstAired,
    this.runtime,
    this.certification,
    this.network,
    this.country,
    this.trailer,
    this.homepage,
    this.status,
    this.rating,
    this.votes,
    this.language,
    this.genres,
    this.airedEpisodes,
  });
  
  factory TraktShow.fromJson(Map<String, dynamic> json) => _$TraktShowFromJson(json);
  Map<String, dynamic> toJson() => _$TraktShowToJson(this);
}
