import 'package:dio/dio.dart';
import '../../models/trakt/trakt_genre.dart';

class TraktGenresApi {
  final Dio _dio;
  
  TraktGenresApi(this._dio);
  
  Future<List<TraktGenre>> getMovieGenres() async {
    final response = await _dio.get('/genres/movies');
    
    return (response.data as List)
        .map((json) => TraktGenre.fromJson(json))
        .toList();
  }
  
  Future<List<TraktGenre>> getShowGenres() async {
    final response = await _dio.get('/genres/shows');
    
    return (response.data as List)
        .map((json) => TraktGenre.fromJson(json))
        .toList();
  }
}
