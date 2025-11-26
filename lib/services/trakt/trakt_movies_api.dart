import 'package:dio/dio.dart';
import '../../core/config/trakt_config.dart';
import '../../models/trakt/trakt_movie.dart';

class TraktMoviesApi {
  final Dio _dio;
  
  TraktMoviesApi(this._dio);
  
  Future<List<TraktTrendingMovie>> getTrending({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/trending',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktTrendingMovie.fromJson(json))
        .toList();
  }
  
  Future<List<TraktMovie>> getPopular({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/popular',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    // Debug logging
    print('Popular movies API response (first item): ${(response.data as List).isNotEmpty ? (response.data as List)[0] : "empty"}');
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json))
        .toList();
  }
  
  Future<List<TraktAnticipatedMovie>> getAnticipated({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/anticipated',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktAnticipatedMovie.fromJson(json))
        .toList();
  }
  
  Future<List<TraktMovie>> getPlayed({
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/played',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie'] ?? json))
        .toList();
  }
  
  Future<List<TraktMovie>> getWatched({
    String period = 'weekly',
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/watched/$period',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie'] ?? json))
        .toList();
  }
  
  Future<List<TraktMovie>> getFavorited({
    String period = 'weekly',
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/favorited/$period',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie'] ?? json))
        .toList();
  }
  
  Future<List<TraktMovie>> getCollected({
    String period = 'weekly',
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/collected/$period',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie'] ?? json))
        .toList();
  }
  
  Future<TraktMovie> getSummary(
    String traktSlug, {
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/$traktSlug',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return TraktMovie.fromJson(response.data);
  }
  
  Future<List<TraktMovie>> getRelated(
    String movieId, {
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/movies/$movieId/related',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json))
        .toList();
  }
  
  Future<List<Map<String, dynamic>>> getMyMovies({
    String? startDate,
    int days = 7,
  }) async {
    final start = startDate ?? DateTime.now().toIso8601String().split('T')[0];
    
    final response = await _dio.get(
      '/calendars/my/movies/$start/$days',
      queryParameters: {
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => json as Map<String, dynamic>)
        .toList();
  }
  
  Future<List<TraktMovie>> getRecentlyUpdatedMovies({
    int limit = 20,
  }) async {
    // Get date 7 days ago, rounded to the hour
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    final formattedDate = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T${startDate.hour.toString().padLeft(2, '0')}:00:00Z';
    
    final response = await _dio.get(
      '/movies/updates/$formattedDate',
      queryParameters: {
        'limit': limit,
        'extended': 'full',
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie'] ?? json))
        .toList();
  }
}
