import 'package:dio/dio.dart';
import '../../models/trakt/trakt_movie.dart';
import '../../core/config/trakt_config.dart';

class TraktRecommendationsApi {
  final Dio _dio;
  
  TraktRecommendationsApi(this._dio);
  
  Future<List<TraktMovie>> getMovieRecommendations({
    bool ignoreCollected = false,
    bool ignoreWatchlisted = false,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/recommendations/movies',
      queryParameters: {
        'ignore_collected': ignoreCollected,
        'ignore_watchlisted': ignoreWatchlisted,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json))
        .toList();
  }
  
  Future<List<dynamic>> getShowRecommendations({
    bool ignoreCollected = false,
    bool ignoreWatchlisted = false,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/recommendations/shows',
      queryParameters: {
        'ignore_collected': ignoreCollected,
        'ignore_watchlisted': ignoreWatchlisted,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return response.data as List;
  }
}
