import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../models/trakt/trakt_auth.dart';

class TraktAuthApi {
  final Dio _dio;
  
  TraktAuthApi(this._dio);
  
  Future<TraktAccessToken> requestAccessToken({
    required String redirectUri,
    required String code,
  }) async {
    final response = await _dio.post(
      '/oauth/token',
      data: {
        'code': code,
        'client_id': AppConfig.traktClientId,
        'client_secret': AppConfig.traktClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );
    
    return TraktAccessToken.fromJson(response.data);
  }
  
  Future<TraktAccessToken> refreshAccessToken({
    required String redirectUri,
    required String refreshToken,
  }) async {
    final response = await _dio.post(
      '/oauth/token',
      data: {
        'refresh_token': refreshToken,
        'client_id': AppConfig.traktClientId,
        'client_secret': AppConfig.traktClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'refresh_token',
      },
    );
    
    return TraktAccessToken.fromJson(response.data);
  }
  
  Future<void> revokeToken(String token) async {
    await _dio.post(
      '/oauth/revoke',
      data: {
        'token': token,
        'client_id': AppConfig.traktClientId,
        'client_secret': AppConfig.traktClientSecret,
      },
    );
  }
}
