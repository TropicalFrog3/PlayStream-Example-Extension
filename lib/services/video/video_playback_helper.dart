import 'package:flutter/material.dart';
import '../extension/extension_manager.dart';
import '../../models/extension/stream_server.dart';
import '../../models/extension/search_options.dart';
import '../../models/extension/media.dart';
import '../../views/screens/player_screen.dart';

/// Helper class for initiating video playback with extension support
class VideoPlaybackHelper {
  final ExtensionManager extensionManager;

  VideoPlaybackHelper(this.extensionManager);

  /// Play a movie using extension system
  /// 
  /// Searches for the movie across all enabled extensions,
  /// retrieves available servers, and launches the player screen.
  Future<void> playMovie({
    required BuildContext context,
    required String title,
    int? year,
    String? movieId,
    String? extensionId,
    String? imdbId,
    String? tmdbId,
  }) async {
    try {
      List<StreamServer> servers = [];
      String? selectedExtensionId = extensionId;
      String? selectedMovieId = movieId;

      // If we don't have a specific extension/movie ID, search for it
      if (selectedExtensionId == null || selectedMovieId == null) {
        // Create SearchOptions with Media metadata
        final searchOptions = SearchOptions(
          media: Media(
            id: 0,
            imdbId: imdbId,
            tmdbId: tmdbId,
            format: 'MOVIE',
            englishTitle: title,
            isAdult: false,
          ),
          query: title,
          year: year,
        );
        
        final searchResults = await extensionManager.searchAll(searchOptions);

        if (searchResults.isEmpty) {
          _showError(context, 'Movie not found in any extension');
          return;
        }

        // Use the first result and first enabled extension
        final firstResult = searchResults.first;
        final enabledExtensions = extensionManager.getEnabledExtensions();
        
        if (enabledExtensions.isEmpty) {
          _showError(context, 'No extensions enabled');
          return;
        }
        
        selectedExtensionId = enabledExtensions.first;
        selectedMovieId = firstResult.id;
      }

      // Get servers for the movie
      servers = await extensionManager.findMovieServers(
        selectedExtensionId,
        selectedMovieId,
      );

      if (servers.isEmpty) {
        _showError(context, 'No servers available for this movie');
        return;
      }

      // Navigate to player screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              title: title,
              server: servers.first,
              availableServers: servers,
              contentId: 'movie:$selectedMovieId',
            ),
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Error loading movie: $e');
    }
  }

  /// Play a TV show episode using extension system
  /// 
  /// Searches for the show across all enabled extensions,
  /// retrieves available servers for the specific episode,
  /// and launches the player screen.
  Future<void> playEpisode({
    required BuildContext context,
    required String title,
    required int season,
    required int episode,
    String? showId,
    String? extensionId,
    String? imdbId,
    String? tmdbId,
  }) async {
    try {
      List<StreamServer> servers = [];
      String? selectedExtensionId = extensionId;
      String? selectedShowId = showId;

      // If we don't have a specific extension/show ID, search for it
      if (selectedExtensionId == null || selectedShowId == null) {
        // Create SearchOptions with Media metadata
        final searchOptions = SearchOptions(
          media: Media(
            id: 0,
            imdbId: imdbId,
            tmdbId: tmdbId,
            format: 'TV',
            englishTitle: title,
            isAdult: false,
          ),
          query: title,
        );
        
        final searchResults = await extensionManager.searchAll(searchOptions);

        if (searchResults.isEmpty) {
          _showError(context, 'Show not found in any extension');
          return;
        }

        // Use the first result and first enabled extension
        final firstResult = searchResults.first;
        final enabledExtensions = extensionManager.getEnabledExtensions();
        
        if (enabledExtensions.isEmpty) {
          _showError(context, 'No extensions enabled');
          return;
        }
        
        selectedExtensionId = enabledExtensions.first;
        selectedShowId = firstResult.id;
      }

      // Get servers for the episode
      servers = await extensionManager.findEpisodeServers(
        selectedExtensionId,
        selectedShowId,
        season,
        episode,
      );

      if (servers.isEmpty) {
        _showError(context, 'No servers available for this episode');
        return;
      }

      // Navigate to player screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              title: '$title - S${season}E$episode',
              server: servers.first,
              availableServers: servers,
              contentId: 'episode:$selectedShowId:S${season}E$episode',
            ),
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Error loading episode: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
