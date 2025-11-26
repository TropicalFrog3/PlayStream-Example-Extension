import 'package:json_annotation/json_annotation.dart';

part 'trakt_auth.g.dart';

@JsonSerializable()
class TraktAccessToken {
  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  final String scope;
  @JsonKey(name: 'created_at')
  final int createdAt;
  
  TraktAccessToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
    required this.scope,
    required this.createdAt,
  });
  
  factory TraktAccessToken.fromJson(Map<String, dynamic> json) => _$TraktAccessTokenFromJson(json);
  Map<String, dynamic> toJson() => _$TraktAccessTokenToJson(this);
}

@JsonSerializable()
class TraktTokenRequest {
  final String code;
  @JsonKey(name: 'client_id')
  final String clientId;
  @JsonKey(name: 'client_secret')
  final String clientSecret;
  @JsonKey(name: 'redirect_uri')
  final String redirectUri;
  @JsonKey(name: 'grant_type')
  final String grantType;
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  
  TraktTokenRequest({
    required this.code,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.grantType,
    this.refreshToken,
  });
  
  factory TraktTokenRequest.fromJson(Map<String, dynamic> json) => _$TraktTokenRequestFromJson(json);
  Map<String, dynamic> toJson() => _$TraktTokenRequestToJson(this);
}

enum TraktGrantType {
  @JsonValue('authorization_code')
  authorizationCode,
  @JsonValue('refresh_token')
  refreshToken,
}
