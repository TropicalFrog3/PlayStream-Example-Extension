import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/extension/search_result.dart';
import '../models/extension/media.dart';
import '../models/extension/show_episode_details.dart';
import '../services/extension/movieshow_stream_manager.dart';

/// Provider for the MovieShowStreamRepository
final movieShowStreamRepositoryProvider =
    Provider<MovieShowStreamRepository>((ref) {
  throw UnimplementedError(
      'MovieShowStreamRepository must be initialized in main.dart');
});

/// Repository handling business logic for movie/show streaming
/// Includes automatic matching, manual mapping, and fuzzy search
class MovieShowStreamRepository {
  final MovieShowStreamManager _streamManager;
  final Box<String> _mappingBox;
  final Logger _logger;

  MovieShowStreamRepository._({
    required MovieShowStreamManager streamManager,
    required Box<String> mappingBox,
    required Logger logger,
  })  : _streamManager = streamManager,
        _mappingBox = mappingBox,
        _logger = logger;

  /// Factory constructor to create and initialize repository
  static Future<MovieShowStreamRepository> create(
      MovieShowStreamManager streamManager) async {
    // Open Hive box for manual mappings
    final mappingBox =
        await Hive.openBox<String>('movieshow_stream_mappings');

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

    return MovieShowStreamRepository._(
      streamManager: streamManager,
      mappingBox: mappingBox,
      logger: logger,
    );
  }

  /// Find the best matching search result automatically
  ///
  /// Uses fuzzy matching against multiple title variations
  /// Returns null if no good match is found
  Future<SearchResult?> findBestMatch({
    required String providerId,
    required Media media,
    required List<String> titles,
  }) async {
    _logger.d(
        'Finding best match for: ${media.englishTitle} (titles: ${titles.length})');

    try {
      // Check for manual mapping first
      final manualMapping = await getManualMapping(
        providerId: providerId,
        tmdbId: media.tmdbId ?? '',
      );

      if (manualMapping != null) {
        _logger.i('Using manual mapping: $manualMapping');
        // Search for the specific mapped content
        final results = await _streamManager.search(
          providerId: providerId,
          media: media,
          query: manualMapping,
          mediaType: media.format?.toLowerCase(),
        );

        if (results.isNotEmpty) {
          return results.first;
        }
      }

      // Try each title variation
      for (var title in titles) {
        final results = await _streamManager.search(
          providerId: providerId,
          media: media,
          query: title,
          mediaType: media.format?.toLowerCase(),
        );

        if (results.isEmpty) continue;

        // Find best match using fuzzy matching
        final bestMatch = _getBestSearchResult(results, titles);
        if (bestMatch != null) {
          _logger.i('Found best match: ${bestMatch.title}');
          return bestMatch;
        }
      }

      _logger.w('No good match found');
      return null;
    } catch (e, stackTrace) {
      _logger.e('Failed to find best match',
          error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Save a manual mapping between TMDB content and provider content
  ///
  /// Used when automatic matching fails or user wants to override
  Future<void> saveManualMapping({
    required String providerId,
    required String tmdbId,
    required String providerContentId,
  }) async {
    final key = '${providerId}_$tmdbId';
    await _mappingBox.put(key, providerContentId);
    _logger.i('Saved manual mapping: $key -> $providerContentId');
  }

  /// Get a manual mapping if it exists
  Future<String?> getManualMapping({
    required String providerId,
    required String tmdbId,
  }) async {
    final key = '${providerId}_$tmdbId';
    return _mappingBox.get(key);
  }

  /// Delete a manual mapping
  Future<void> deleteManualMapping({
    required String providerId,
    required String tmdbId,
  }) async {
    final key = '${providerId}_$tmdbId';
    await _mappingBox.delete(key);
    _logger.i('Deleted manual mapping: $key');
  }

  /// Get all episodes for a TV show (all seasons)
  ///
  /// Useful for building a complete episode list UI
  Future<List<ShowEpisodeDetails>> getAllEpisodes({
    required String providerId,
    required String showId,
  }) async {
    _logger.d('Getting all episodes for show: $showId');

    try {
      // Get all seasons
      final seasons = await _streamManager.getSeasons(
        providerId: providerId,
        showId: showId,
      );

      // Get episodes for each season
      final allEpisodes = <ShowEpisodeDetails>[];
      for (var season in seasons) {
        final episodes = await _streamManager.getSeasonEpisodes(
          providerId: providerId,
          showId: showId,
          seasonNumber: season.seasonNumber,
        );
        allEpisodes.addAll(episodes);
      }

      _logger.i('Got ${allEpisodes.length} total episodes');
      return allEpisodes;
    } catch (e, stackTrace) {
      _logger.e('Failed to get all episodes',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fuzzy match search results against known titles
  ///
  /// Returns the best matching result or null if no good match
  SearchResult? _getBestSearchResult(
    List<SearchResult> results,
    List<String> titles,
  ) {
    if (results.isEmpty) return null;

    // Simple scoring: exact match > contains > starts with
    SearchResult? bestMatch;
    int bestScore = 0;

    for (var result in results) {
      final resultTitle = result.title.toLowerCase();

      for (var title in titles) {
        final searchTitle = title.toLowerCase();
        int score = 0;

        // Exact match (highest priority)
        if (resultTitle == searchTitle) {
          score = 100;
        }
        // Starts with
        else if (resultTitle.startsWith(searchTitle) ||
            searchTitle.startsWith(resultTitle)) {
          score = 75;
        }
        // Contains
        else if (resultTitle.contains(searchTitle) ||
            searchTitle.contains(resultTitle)) {
          score = 50;
        }
        // Word match (split by spaces and check overlap)
        else {
          final resultWords = resultTitle.split(' ');
          final searchWords = searchTitle.split(' ');
          final matchingWords = resultWords
              .where((word) => searchWords.contains(word))
              .length;
          if (matchingWords > 0) {
            score = (matchingWords / searchWords.length * 40).round();
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = result;
        }
      }
    }

    // Only return if score is above threshold
    if (bestScore >= 50) {
      _logger.d('Best match score: $bestScore for ${bestMatch?.title}');
      return bestMatch;
    }

    return null;
  }
}
