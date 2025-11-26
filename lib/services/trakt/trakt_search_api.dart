import 'package:dio/dio.dart';
import '../../core/config/trakt_config.dart';
import '../../models/trakt/trakt_movie.dart';
import '../../models/trakt/trakt_show.dart';

class TraktSearchApi {
  final Dio _dio;
  
  TraktSearchApi(this._dio);
  
  Future<List<dynamic>> search({
    required String query,
    String? type,
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/search/${type ?? 'movie,show'}',
      queryParameters: {
        'query': query,
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return response.data as List;
  }
  
  Future<List<TraktMovie>> searchMovies({
    required String query,
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/search/movie',
      queryParameters: {
        'query': query,
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMovie.fromJson(json['movie']))
        .toList();
  }
  
  Future<List<TraktShow>> searchShows({
    required String query,
    int page = 1,
    int limit = 10,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/search/show',
      queryParameters: {
        'query': query,
        'page': page,
        'limit': limit,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktShow.fromJson(json['show']))
        .toList();
  }
  
  /// ID Lookup - Search by external ID (IMDB, TMDB, TVDB, etc.)
  /// 
  /// Endpoint: GET /search/:id_type/:id
  /// 
  /// [idType] can be: trakt, imdb, tmdb, tvdb
  /// [id] is the actual ID value
  /// [type] optional filter: movie, show, episode, person
  Future<List<dynamic>> idLookup({
    required String idType,
    required String id,
    String? type,
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/search/$idType/$id',
      queryParameters: {
        if (type != null) 'type': type,
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return response.data as List;
  }
}
