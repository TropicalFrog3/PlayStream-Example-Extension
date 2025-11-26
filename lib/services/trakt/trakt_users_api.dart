import 'package:dio/dio.dart';
import '../../core/config/trakt_config.dart';
import '../../models/trakt/trakt_user.dart';

class TraktUsersApi {
  final Dio _dio;
  
  TraktUsersApi(this._dio);
  
  Future<TraktUserSettings> getSettings() async {
    final response = await _dio.get('/users/settings');
    return TraktUserSettings.fromJson(response.data);
  }
  
  Future<TraktUser> getProfile(
    String userSlug, {
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/users/$userSlug',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return TraktUser.fromJson(response.data);
  }
  
  Future<List<TraktUser>> getFollowers(
    String userSlug, {
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/users/$userSlug/followers',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktUser.fromJson(json))
        .toList();
  }
  
  Future<List<TraktUser>> getFollowing(
    String userSlug, {
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/users/$userSlug/following',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktUser.fromJson(json))
        .toList();
  }
}
