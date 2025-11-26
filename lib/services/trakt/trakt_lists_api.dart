import 'package:dio/dio.dart';
import '../../models/trakt/trakt_list.dart';

class TraktListsApi {
  final Dio _dio;
  
  TraktListsApi(this._dio);
  
  Future<List<TraktTrendingList>> getTrendingLists({
    String type = 'personal',
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/lists/trending/$type',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktTrendingList.fromJson(json))
        .toList();
  }
  
  Future<List<TraktTrendingList>> getPopularLists({
    String type = 'personal',
    int page = 1,
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '/lists/popular/$type',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktTrendingList.fromJson(json))
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getListItems({
    required String username,
    required String listId,
    String extended = 'full',
  }) async {
    final response = await _dio.get(
      '/users/$username/lists/$listId/items',
      queryParameters: {
        'extended': extended,
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
}
