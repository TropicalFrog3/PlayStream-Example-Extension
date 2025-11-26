import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/config/trakt_config.dart';
import '../../core/network/dio_client.dart';
import 'trakt_auth_api.dart';
import 'trakt_movies_api.dart';
import 'trakt_shows_api.dart';
import 'trakt_sync_api.dart';
import 'trakt_users_api.dart';
import 'trakt_search_api.dart';
import 'trakt_genres_api.dart';
import 'trakt_lists_api.dart';
import 'trakt_recommendations_api.dart';

class TraktClient {
  late final DioClient _dioClient;
  late final TraktAuthApi auth;
  late final TraktMoviesApi movies;
  late final TraktShowsApi shows;
  late final TraktSyncApi sync;
  late final TraktUsersApi users;
  late final TraktSearchApi search;
  late final TraktGenresApi genres;
  late final TraktListsApi lists;
  late final TraktRecommendationsApi recommendations;
  
  TraktClient() {
    _dioClient = DioClient();
    
    auth = TraktAuthApi(_dioClient.dio);
    movies = TraktMoviesApi(_dioClient.dio);
    shows = TraktShowsApi(_dioClient.dio);
    sync = TraktSyncApi(_dioClient.dio);
    users = TraktUsersApi(_dioClient.dio);
    search = TraktSearchApi(_dioClient.dio);
    genres = TraktGenresApi(_dioClient.dio);
    lists = TraktListsApi(_dioClient.dio);
    recommendations = TraktRecommendationsApi(_dioClient.dio);
  }
  
  void setAuthToken(String token) {
    _dioClient.setAuthToken(token);
  }
  
  void removeAuthToken() {
    _dioClient.removeAuthToken();
  }
  
  Dio get dio => _dioClient.dio;
}
