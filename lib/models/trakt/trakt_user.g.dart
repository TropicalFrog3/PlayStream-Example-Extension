// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktUser _$TraktUserFromJson(Map<String, dynamic> json) => TraktUser(
      username: json['username'] as String?,
      private: json['private'] as bool?,
      name: json['name'] as String?,
      vip: json['vip'] as bool?,
      vipEp: json['vip_ep'] as bool?,
      ids: json['ids'] == null
          ? null
          : TraktUserIds.fromJson(json['ids'] as Map<String, dynamic>),
      joinedAt: json['joined_at'] as String?,
      location: json['location'] as String?,
      about: json['about'] as String?,
      gender: json['gender'] as String?,
      age: (json['age'] as num?)?.toInt(),
      images: json['images'] == null
          ? null
          : TraktUserImages.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktUserToJson(TraktUser instance) => <String, dynamic>{
      'username': instance.username,
      'private': instance.private,
      'name': instance.name,
      'vip': instance.vip,
      'vip_ep': instance.vipEp,
      'ids': instance.ids,
      'joined_at': instance.joinedAt,
      'location': instance.location,
      'about': instance.about,
      'gender': instance.gender,
      'age': instance.age,
      'images': instance.images,
    };

TraktUserIds _$TraktUserIdsFromJson(Map<String, dynamic> json) => TraktUserIds(
      slug: json['slug'] as String?,
    );

Map<String, dynamic> _$TraktUserIdsToJson(TraktUserIds instance) =>
    <String, dynamic>{
      'slug': instance.slug,
    };

TraktUserImages _$TraktUserImagesFromJson(Map<String, dynamic> json) =>
    TraktUserImages(
      avatar: json['avatar'] == null
          ? null
          : TraktUserAvatar.fromJson(json['avatar'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktUserImagesToJson(TraktUserImages instance) =>
    <String, dynamic>{
      'avatar': instance.avatar,
    };

TraktUserAvatar _$TraktUserAvatarFromJson(Map<String, dynamic> json) =>
    TraktUserAvatar(
      full: json['full'] as String?,
    );

Map<String, dynamic> _$TraktUserAvatarToJson(TraktUserAvatar instance) =>
    <String, dynamic>{
      'full': instance.full,
    };

TraktUserSettings _$TraktUserSettingsFromJson(Map<String, dynamic> json) =>
    TraktUserSettings(
      user: json['user'] == null
          ? null
          : TraktUser.fromJson(json['user'] as Map<String, dynamic>),
      account: json['account'] == null
          ? null
          : TraktAccount.fromJson(json['account'] as Map<String, dynamic>),
      connections: json['connections'] == null
          ? null
          : TraktConnections.fromJson(
              json['connections'] as Map<String, dynamic>),
      sharingText: json['sharing_text'] == null
          ? null
          : TraktSharingText.fromJson(
              json['sharing_text'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TraktUserSettingsToJson(TraktUserSettings instance) =>
    <String, dynamic>{
      'user': instance.user,
      'account': instance.account,
      'connections': instance.connections,
      'sharing_text': instance.sharingText,
    };

TraktAccount _$TraktAccountFromJson(Map<String, dynamic> json) => TraktAccount(
      timezone: json['timezone'] as String?,
      dateFormat: json['date_format'] as String?,
      time_24hr: json['time_24hr'] as bool?,
      coverImage: json['cover_image'] as String?,
    );

Map<String, dynamic> _$TraktAccountToJson(TraktAccount instance) =>
    <String, dynamic>{
      'timezone': instance.timezone,
      'date_format': instance.dateFormat,
      'time_24hr': instance.time_24hr,
      'cover_image': instance.coverImage,
    };

TraktConnections _$TraktConnectionsFromJson(Map<String, dynamic> json) =>
    TraktConnections(
      twitter: json['twitter'] as bool?,
      google: json['google'] as bool?,
      tumblr: json['tumblr'] as bool?,
      medium: json['medium'] as bool?,
      slack: json['slack'] as bool?,
    );

Map<String, dynamic> _$TraktConnectionsToJson(TraktConnections instance) =>
    <String, dynamic>{
      'twitter': instance.twitter,
      'google': instance.google,
      'tumblr': instance.tumblr,
      'medium': instance.medium,
      'slack': instance.slack,
    };

TraktSharingText _$TraktSharingTextFromJson(Map<String, dynamic> json) =>
    TraktSharingText(
      watching: json['watching'] as String?,
      watched: json['watched'] as String?,
    );

Map<String, dynamic> _$TraktSharingTextToJson(TraktSharingText instance) =>
    <String, dynamic>{
      'watching': instance.watching,
      'watched': instance.watched,
    };
