import 'search_result.dart';
import 'movie_details.dart';
import 'episode_details.dart';
import 'stream_server.dart';
import 'extension_settings.dart';

/// Abstract base class defining the interface that all extension providers must implement.
/// This interface standardizes how the app communicates with different scraper extensions.
abstract class ExtensionProvider {
  /// Unique identifier for the extension
  String get extensionId;

  /// Display name of the extension
  String get name;

  /// Version of the extension
  String get version;

  /// Search for content (movies/shows) based on a query string.
  /// 
  /// [query] is the search query string.
  /// [imdbId] is an optional IMDB ID for direct lookup.
  /// [tmdbId] is an optional TMDB ID for direct lookup.
  /// [mediaType] is an optional media type: "movie" or "tv".
  /// 
  /// Returns a list of [SearchResult] objects matching the query.
  /// Throws [ExtensionException] if the search fails.
  Future<List<SearchResult>> search(
    String query, {
    String? imdbId,
    String? tmdbId,
    String? mediaType,
  });

  /// Find detailed information and sources for a specific movie.
  /// 
  /// [movieId] is the unique identifier for the movie within this extension.
  /// Returns [MovieDetails] containing movie information and available servers.
  /// Throws [ExtensionException] if the movie cannot be found.
  Future<MovieDetails> findMovie(String movieId);

  /// Find detailed information and sources for a specific TV show episode.
  /// 
  /// [showId] is the unique identifier for the show within this extension.
  /// [season] is the season number.
  /// [episode] is the episode number within the season.
  /// Returns [EpisodeDetails] containing episode information and available servers.
  /// Throws [ExtensionException] if the episode cannot be found.
  Future<EpisodeDetails> findEpisode(String showId, int season, int episode);

  /// Get available streaming servers for a specific movie.
  /// 
  /// [movieId] is the unique identifier for the movie within this extension.
  /// Returns a list of [StreamServer] objects representing available streaming sources.
  /// Throws [ExtensionException] if servers cannot be retrieved.
  Future<List<StreamServer>> findMovieServers(String movieId);

  /// Get available streaming servers for a specific TV show episode.
  /// 
  /// [showId] is the unique identifier for the show within this extension.
  /// [season] is the season number.
  /// [episode] is the episode number within the season.
  /// Returns a list of [StreamServer] objects representing available streaming sources.
  /// Throws [ExtensionException] if servers cannot be retrieved.
  Future<List<StreamServer>> findEpisodeServers(String showId, int season, int episode);

  /// Get extension settings and configuration.
  /// 
  /// Returns [ExtensionSettings] containing the extension's configuration,
  /// available servers, and user preferences.
  /// Throws [ExtensionException] if settings cannot be retrieved.
  Future<ExtensionSettings> getSettings();
}
