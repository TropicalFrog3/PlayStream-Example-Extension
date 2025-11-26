// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TraktAccessToken _$TraktAccessTokenFromJson(Map<String, dynamic> json) =>
    TraktAccessToken(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      refreshToken: json['refresh_token'] as String,
      scope: json['scope'] as String,
      createdAt: (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$TraktAccessTokenToJson(TraktAccessToken instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'refresh_token': instance.refreshToken,
      'scope': instance.scope,
      'created_at': instance.createdAt,
    };

TraktTokenRequest _$TraktTokenRequestFromJson(Map<String, dynamic> json) =>
    TraktTokenRequest(
      code: json['code'] as String,
      clientId: json['client_id'] as String,
      clientSecret: json['client_secret'] as String,
      redirectUri: json['redirect_uri'] as String,
      grantType: json['grant_type'] as String,
      refreshToken: json['refresh_token'] as String?,
    );

Map<String, dynamic> _$TraktTokenRequestToJson(TraktTokenRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'client_id': instance.clientId,
      'client_secret': instance.clientSecret,
      'redirect_uri': instance.redirectUri,
      'grant_type': instance.grantType,
      'refresh_token': instance.refreshToken,
    };
