import 'package:dio/dio.dart';
import '../../core/config/trakt_config.dart';
import '../../models/trakt/trakt_sync.dart';

class TraktSyncApi {
  final Dio _dio;
  
  TraktSyncApi(this._dio);
  
  Future<TraktSyncResponse> addToWatchlist(TraktSyncItems items) async {
    final response = await _dio.post(
      '/sync/watchlist',
      data: items.toJson(),
    );
    
    return TraktSyncResponse.fromJson(response.data);
  }
  
  Future<TraktSyncResponse> removeFromWatchlist(TraktSyncItems items) async {
    final response = await _dio.post(
      '/sync/watchlist/remove',
      data: items.toJson(),
    );
    
    return TraktSyncResponse.fromJson(response.data);
  }
  
  Future<TraktSyncResponse> addWatchedHistory(TraktSyncItems items) async {
    final response = await _dio.post(
      '/sync/history',
      data: items.toJson(),
    );
    
    return TraktSyncResponse.fromJson(response.data);
  }
  
  Future<TraktSyncResponse> removeWatchedHistory(TraktSyncItems items) async {
    final response = await _dio.post(
      '/sync/history/remove',
      data: items.toJson(),
    );
    
    return TraktSyncResponse.fromJson(response.data);
  }
  
  Future<List<TraktMediaItem>> getWatchedMovies({
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/sync/watched/movies',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMediaItem.fromJson(json))
        .toList();
  }
  
  Future<List<TraktMediaItem>> getWatchedShows({
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/sync/watched/shows',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMediaItem.fromJson(json))
        .toList();
  }
  
  Future<List<TraktMediaItem>> getWatchlistMovies({
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/sync/watchlist/movies',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMediaItem.fromJson(json))
        .toList();
  }
  
  Future<List<TraktMediaItem>> getWatchlistShows({
    TraktExtended? extended,
  }) async {
    final response = await _dio.get(
      '/sync/watchlist/shows',
      queryParameters: {
        if (extended != null) 'extended': extended.value,
      },
    );
    
    return (response.data as List)
        .map((json) => TraktMediaItem.fromJson(json))
        .toList();
  }
}
