import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../../models/extension/cache_entry.dart';
import '../../models/extension/extension_exception.dart';
import '../../models/extension/search_result.dart';
import '../../models/extension/search_options.dart';
import '../../models/extension/media.dart';
import '../../models/extension/movie_stream_source.dart';
import '../../models/extension/season_details.dart';
import '../../models/extension/show_episode_details.dart';
import '../../models/extension/episode_stream_source.dart';
import '../../models/extension/movieshow_stream_settings.dart';

/// Provider for the MovieShowStreamManager singleton instance
final movieShowStreamManagerProvider = Provider<MovieShowStreamManager>((ref) {
  throw UnimplementedError(
      'MovieShowStreamManager must be initialized in main.dart');
});

/// Service that manages movie/show streaming extension operations
/// Parallel to the anime extension system but adapted for TMDB/IMDB metadata
class MovieShowStreamManager {
  static const MethodChannel _channel =
      MethodChannel('com.playstream/extensions');

  final Box<CacheEntry> _cacheBox;
  final Logger _logger;

  // Cache expiration durations
  static const Duration _searchCacheExpiration = Duration(minutes: 5);
  static const Duration _seasonCacheExpiration = Duration(hours: 24);
  static const Duration _episodeCacheExpiration = Duration(hours: 24);
  static const Duration _movieSourceCacheExpiration = Duration(minutes: 30);
  static const Duration _episodeSourceCacheExpiration = Duration(minutes: 30);
  static const Duration _settingsCacheExpiration = Duration(hours: 1);

  MovieShowStreamManager._({
    required Box<CacheEntry> cacheBox,
    required Logger logger,
  })  : _cacheBox = cacheBox,
        _logger = logger;

  /// Factory constructor to create and initialize MovieShowStreamManager
  static Future<MovieShowStreamManager> create() async {
    // Open Hive box for caching
    final cacheBox =
        await Hive.openBox<CacheEntry>('movieshow_stream_cache');

    // Initialize Logger
    final logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
    );

    return MovieShowStreamManager._(
      cacheBox: cacheBox,
      logger: logger,
    );
  }

  /// Search for movies or TV shows
  ///
  /// [providerId] - Extension provider ID
  /// [media] - Media metadata (TMDB/IMDB)
  /// [query] - Search query string
  /// [mediaType] - Optional: "movie" or "tv"
  Future<List<SearchResult>> search({
    required String providerId,
    required Media media,
    required String query,
    String? mediaType,
  }) async {
    _logger.d(
        'Searching for content: provider=$providerId, query=$query, mediaType=$mediaType');

    // Generate cache key
    final cacheKey = 'search_${providerId}_${query}_${mediaType ?? 'all'}';

    // Check cache
    final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached search results (age: ${cachedEntry.age.inMinutes} minutes)');
      return cachedEntry.data
          .map<SearchResult>((json) =>
              SearchResult.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    try {
      // Create search options
      final options = SearchOptions(
        media: media,
        query: query,
        year: media.startDate?.year,
        mediaType: mediaType,
      );

      // Call native method
      final result = await _channel.invokeMethod('searchMovieShows', {
        'providerId': providerId,
        'options': options.toJson(),
      });

      // Parse results
      final results = (result as List<dynamic>)
          .map((json) =>
              SearchResult.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache results
      await _setCacheEntry(
        cacheKey,
        results.map((r) => r.toJson()).toList(),
        _searchCacheExpiration,
      );

      _logger.i('Found ${results.length} search results');
      return results;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception during search',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Search failed: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to search', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Search failed: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Get streaming sources for a movie
  ///
  /// [providerId] - Extension provider ID
  /// [movieId] - Provider's movie identifier
  /// [server] - Streaming server to use
  Future<MovieStreamSource> getMovieSource({
    required String providerId,
    required String movieId,
    required String server,
  }) async {
    _logger.d(
        'Getting movie source: provider=$providerId, movieId=$movieId, server=$server');

    // Generate cache key
    final cacheKey = 'movie_${providerId}_${movieId}_$server';

    // Check cache
    final cachedEntry = _getCacheEntry<Map<String, dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached movie source');
      return MovieStreamSource.fromJson(cachedEntry.data);
    }

    try {
      // Call native method
      final result = await _channel.invokeMethod('getMovieSource', {
        'providerId': providerId,
        'movieId': movieId,
        'server': server,
      });

      // Parse result
      final source = MovieStreamSource.fromJson(
          Map<String, dynamic>.from(result as Map));

      // Cache result
      await _setCacheEntry(
        cacheKey,
        source.toJson(),
        _movieSourceCacheExpiration,
      );

      _logger.i(
          'Got movie source with ${source.videoSources.length} video sources');
      return source;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception getting movie source',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get movie source: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get movie source',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get movie source: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Get list of seasons for a TV show
  ///
  /// [providerId] - Extension provider ID
  /// [showId] - Provider's show identifier
  Future<List<SeasonDetails>> getSeasons({
    required String providerId,
    required String showId,
  }) async {
    _logger.d('Getting seasons: provider=$providerId, showId=$showId');

    // Generate cache key
    final cacheKey = 'seasons_${providerId}_$showId';

    // Check cache
    final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached seasons list');
      return cachedEntry.data
          .map<SeasonDetails>((json) =>
              SeasonDetails.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    try {
      // Call native method
      final result = await _channel.invokeMethod('getSeasons', {
        'providerId': providerId,
        'showId': showId,
      });

      // Parse results
      final seasons = (result as List<dynamic>)
          .map((json) =>
              SeasonDetails.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache results
      await _setCacheEntry(
        cacheKey,
        seasons.map((s) => s.toJson()).toList(),
        _seasonCacheExpiration,
      );

      _logger.i('Found ${seasons.length} seasons');
      return seasons;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception getting seasons',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get seasons: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get seasons', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get seasons: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Get episodes for a specific season
  ///
  /// [providerId] - Extension provider ID
  /// [showId] - Provider's show identifier
  /// [seasonNumber] - Season number (1, 2, 3, etc.)
  Future<List<ShowEpisodeDetails>> getSeasonEpisodes({
    required String providerId,
    required String showId,
    required int seasonNumber,
  }) async {
    _logger.d(
        'Getting season episodes: provider=$providerId, showId=$showId, season=$seasonNumber');

    // Generate cache key
    final cacheKey = 'episodes_${providerId}_${showId}_S$seasonNumber';

    // Check cache
    final cachedEntry = _getCacheEntry<List<dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached episode list');
      return cachedEntry.data
          .map<ShowEpisodeDetails>((json) => ShowEpisodeDetails.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();
    }

    try {
      // Call native method
      final result = await _channel.invokeMethod('getSeasonEpisodes', {
        'providerId': providerId,
        'showId': showId,
        'seasonNumber': seasonNumber,
      });

      // Parse results
      final episodes = (result as List<dynamic>)
          .map((json) => ShowEpisodeDetails.fromJson(
              Map<String, dynamic>.from(json as Map)))
          .toList();

      // Cache results
      await _setCacheEntry(
        cacheKey,
        episodes.map((e) => e.toJson()).toList(),
        _episodeCacheExpiration,
      );

      _logger.i('Found ${episodes.length} episodes');
      return episodes;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception getting episodes',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get episodes: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get episodes', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get episodes: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Get streaming sources for a TV show episode
  ///
  /// [providerId] - Extension provider ID
  /// [episode] - Episode details
  /// [server] - Streaming server to use
  Future<EpisodeStreamSource> getEpisodeSource({
    required String providerId,
    required ShowEpisodeDetails episode,
    required String server,
  }) async {
    _logger.d(
        'Getting episode source: provider=$providerId, episode=S${episode.seasonNumber}E${episode.episodeNumber}, server=$server');

    // Generate cache key
    final cacheKey =
        'episode_${providerId}_${episode.id}_S${episode.seasonNumber}E${episode.episodeNumber}_$server';

    // Check cache
    final cachedEntry = _getCacheEntry<Map<String, dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached episode source');
      return EpisodeStreamSource.fromJson(cachedEntry.data);
    }

    try {
      // Call native method
      final result = await _channel.invokeMethod('getEpisodeSource', {
        'providerId': providerId,
        'episode': episode.toJson(),
        'server': server,
      });

      // Parse result
      final source = EpisodeStreamSource.fromJson(
          Map<String, dynamic>.from(result as Map));

      // Cache result
      await _setCacheEntry(
        cacheKey,
        source.toJson(),
        _episodeSourceCacheExpiration,
      );

      _logger.i(
          'Got episode source with ${source.videoSources.length} video sources');
      return source;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception getting episode source',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get episode source: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get episode source',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get episode source: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Get provider settings
  ///
  /// [providerId] - Extension provider ID
  Future<MovieShowStreamSettings> getSettings({
    required String providerId,
  }) async {
    _logger.d('Getting provider settings: provider=$providerId');

    // Generate cache key
    final cacheKey = 'settings_$providerId';

    // Check cache
    final cachedEntry = _getCacheEntry<Map<String, dynamic>>(cacheKey);
    if (cachedEntry != null) {
      _logger.i('Using cached settings');
      return MovieShowStreamSettings.fromJson(cachedEntry.data);
    }

    try {
      // Call native method
      final result = await _channel.invokeMethod('getMovieShowSettings', {
        'providerId': providerId,
      });

      // Parse result
      final settings = MovieShowStreamSettings.fromJson(
          Map<String, dynamic>.from(result as Map));

      // Cache result
      await _setCacheEntry(
        cacheKey,
        settings.toJson(),
        _settingsCacheExpiration,
      );

      _logger.i('Got provider settings');
      return settings;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Platform exception getting settings',
          error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get settings: ${e.message}',
        extensionId: providerId,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to get settings', error: e, stackTrace: stackTrace);
      throw ExtensionException(
        type: ExtensionErrorType.methodCallFailed,
        message: 'Failed to get settings: $e',
        extensionId: providerId,
        originalError: e,
      );
    }
  }

  /// Clear all cache for a specific provider
  void clearCache(String? providerId) {
    if (providerId == null) {
      _cacheBox.clear();
      _logger.i('Cleared all cache');
    } else {
      final keysToDelete = _cacheBox.keys
          .where((key) => key.toString().contains(providerId))
          .toList();
      for (var key in keysToDelete) {
        _cacheBox.delete(key);
      }
      _logger.i('Cleared cache for provider: $providerId');
    }
  }

  /// Clear cache for a specific media item
  void clearMediaCache(String tmdbId) {
    final keysToDelete = _cacheBox.keys
        .where((key) => key.toString().contains(tmdbId))
        .toList();
    for (var key in keysToDelete) {
      _cacheBox.delete(key);
    }
    _logger.i('Cleared cache for media: $tmdbId');
  }

  /// Get a cache entry if it exists and is valid
  CacheEntry<T>? _getCacheEntry<T>(String key) {
    final entry = _cacheBox.get(key);
    if (entry != null && entry.isValid) {
      return entry as CacheEntry<T>;
    }
    return null;
  }

  /// Set a cache entry with expiration
  Future<void> _setCacheEntry(
    String key,
    dynamic data,
    Duration expiration,
  ) async {
    final entry = CacheEntry(
      key: key,
      data: data,
      timestamp: DateTime.now(),
      expirationDuration: expiration,
    );
    await _cacheBox.put(key, entry);
  }
}
