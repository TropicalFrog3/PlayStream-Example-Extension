import 'package:json_annotation/json_annotation.dart';

part 'trakt_user.g.dart';

@JsonSerializable()
class TraktUser {
  final String? username;
  final bool? private;
  final String? name;
  final bool? vip;
  @JsonKey(name: 'vip_ep')
  final bool? vipEp;
  final TraktUserIds? ids;
  @JsonKey(name: 'joined_at')
  final String? joinedAt;
  final String? location;
  final String? about;
  final String? gender;
  final int? age;
  final TraktUserImages? images;
  
  TraktUser({
    this.username,
    this.private,
    this.name,
    this.vip,
    this.vipEp,
    this.ids,
    this.joinedAt,
    this.location,
    this.about,
    this.gender,
    this.age,
    this.images,
  });
  
  factory TraktUser.fromJson(Map<String, dynamic> json) => _$TraktUserFromJson(json);
  Map<String, dynamic> toJson() => _$TraktUserToJson(this);
}

@JsonSerializable()
class TraktUserIds {
  final String? slug;
  
  TraktUserIds({this.slug});
  
  factory TraktUserIds.fromJson(Map<String, dynamic> json) => _$TraktUserIdsFromJson(json);
  Map<String, dynamic> toJson() => _$TraktUserIdsToJson(this);
}

@JsonSerializable()
class TraktUserImages {
  final TraktUserAvatar? avatar;
  
  TraktUserImages({this.avatar});
  
  factory TraktUserImages.fromJson(Map<String, dynamic> json) => _$TraktUserImagesFromJson(json);
  Map<String, dynamic> toJson() => _$TraktUserImagesToJson(this);
}

@JsonSerializable()
class TraktUserAvatar {
  final String? full;
  
  TraktUserAvatar({this.full});
  
  factory TraktUserAvatar.fromJson(Map<String, dynamic> json) => _$TraktUserAvatarFromJson(json);
  Map<String, dynamic> toJson() => _$TraktUserAvatarToJson(this);
}

@JsonSerializable()
class TraktUserSettings {
  final TraktUser? user;
  final TraktAccount? account;
  final TraktConnections? connections;
  @JsonKey(name: 'sharing_text')
  final TraktSharingText? sharingText;
  
  TraktUserSettings({
    this.user,
    this.account,
    this.connections,
    this.sharingText,
  });
  
  factory TraktUserSettings.fromJson(Map<String, dynamic> json) => _$TraktUserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$TraktUserSettingsToJson(this);
}

@JsonSerializable()
class TraktAccount {
  final String? timezone;
  @JsonKey(name: 'date_format')
  final String? dateFormat;
  final bool? time_24hr;
  @JsonKey(name: 'cover_image')
  final String? coverImage;
  
  TraktAccount({
    this.timezone,
    this.dateFormat,
    this.time_24hr,
    this.coverImage,
  });
  
  factory TraktAccount.fromJson(Map<String, dynamic> json) => _$TraktAccountFromJson(json);
  Map<String, dynamic> toJson() => _$TraktAccountToJson(this);
}

@JsonSerializable()
class TraktConnections {
  final bool? twitter;
  final bool? google;
  final bool? tumblr;
  final bool? medium;
  final bool? slack;
  
  TraktConnections({
    this.twitter,
    this.google,
    this.tumblr,
    this.medium,
    this.slack,
  });
  
  factory TraktConnections.fromJson(Map<String, dynamic> json) => _$TraktConnectionsFromJson(json);
  Map<String, dynamic> toJson() => _$TraktConnectionsToJson(this);
}

@JsonSerializable()
class TraktSharingText {
  final String? watching;
  final String? watched;
  
  TraktSharingText({
    this.watching,
    this.watched,
  });
  
  factory TraktSharingText.fromJson(Map<String, dynamic> json) => _$TraktSharingTextFromJson(json);
  Map<String, dynamic> toJson() => _$TraktSharingTextToJson(this);
}

enum TraktUserSlug {
  me('me');
  
  final String name;
  const TraktUserSlug(this.name);
}
