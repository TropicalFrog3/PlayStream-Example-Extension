import 'search_result.dart';
import 'search_options.dart';
import 'movie_stream_source.dart';
import 'season_details.dart';
import 'show_episode_details.dart';
import 'episode_stream_source.dart';
import 'movieshow_stream_settings.dart';

/// Interface for movie/show streaming provider extensions
/// Parallel to the anime streaming system but adapted for TMDB/IMDB metadata
abstract class MovieShowStreamProvider {
  /// Unique identifier for the extension
  String get extensionId;

  /// Display name of the extension
  String get name;

  /// Version of the extension
  String get version;

  /// Search for movies or TV shows
  /// 
  /// [options] contains search parameters including TMDB/IMDB metadata
  /// Returns a list of [SearchResult] objects matching the query
  Future<List<SearchResult>> search(SearchOptions options);

  /// Get available streaming servers for this provider
  /// 
  /// Returns a list of server identifiers (e.g., ["server1", "server2"])
  List<String> getStreamServers();

  /// Get streaming sources for a movie (direct playback)
  /// 
  /// [movieId] is the provider's unique identifier for the movie
  /// [server] is the streaming server to use
  /// Returns [MovieStreamSource] with video sources and subtitles
  Future<MovieStreamSource> getMovieSource(String movieId, String server);

  /// Get list of seasons for a TV show
  /// 
  /// [showId] is the provider's unique identifier for the show
  /// Returns a list of [SeasonDetails] for the show
  Future<List<SeasonDetails>> getSeasons(String showId);

  /// Get episodes for a specific season
  /// 
  /// [showId] is the provider's unique identifier for the show
  /// [seasonNumber] is the season number (1, 2, 3, etc.)
  /// Returns a list of [ShowEpisodeDetails] for the season
  Future<List<ShowEpisodeDetails>> getSeasonEpisodes(
    String showId,
    int seasonNumber,
  );

  /// Get streaming sources for a TV show episode
  /// 
  /// [episode] contains the episode details including season/episode numbers
  /// [server] is the streaming server to use
  /// Returns [EpisodeStreamSource] with video sources and subtitles
  Future<EpisodeStreamSource> getEpisodeSource(
    ShowEpisodeDetails episode,
    String server,
  );

  /// Get provider settings and capabilities
  /// 
  /// Returns [MovieShowStreamSettings] with configuration and capabilities
  MovieShowStreamSettings getSettings();
}
