import 'package:dio/dio.dart';
import '../../core/config/trakt_config.dart';
import '../../models/trakt/trakt_show.dart';

class TraktShowsApi {
  final Dio _dio;
  
  TraktShowsApi(this._dio);
  
  Future<List<TraktShow>> getTrending({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/trending',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json['show']))
        .toList();
  }
  
  Future<List<TraktShow>> getPopular({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/popular',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json))
        .toList();
  }
  
  Future<TraktShow> getSummary(
    String traktSlug, {
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/$traktSlug',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return TraktShow.fromJson(response.data);
  }
  
  Future<List<TraktShow>> getRelated(
    String showId, {
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/$showId/related',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json))
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getMyAiringShows({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/my/shows/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getMyNewShows({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/my/shows/new/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getMySeasonPremieres({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/my/shows/premieres/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getMyFinales({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/my/shows/finales/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getAllNewShows({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/all/shows/new/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<TraktShow>> getAnticipated({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/anticipated',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json['show']))
        .toList();
  }
  
  Future<List<TraktShow>> getWatched({
    String period = 'weekly',
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/shows/watched/$period',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json['show']))
        .toList();
  }
}
