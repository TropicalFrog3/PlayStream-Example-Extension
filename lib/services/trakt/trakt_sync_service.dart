import 'package:logger/logger.dart';
import '../../models/trakt/trakt_sync.dart';
import '../../models/trakt/trakt_movie.dart';
import '../../models/trakt/trakt_show.dart';
import '../profile_service.dart';
import 'trakt_client.dart';
import '../../core/config/app_config.dart';
import '../../core/config/trakt_config.dart';

class TraktSyncService {
  static TraktSyncService? _instance;
  static TraktSyncService get instance {
    _instance ??= TraktSyncService._();
    return _instance!;
  }
  
  TraktSyncService._();
  
  final _logger = Logger();
  final _traktClient = TraktClient();
  final _profileService = ProfileService.instance;
  
  bool _isSyncing = false;
  
  Future<bool> connectTrakt(String authCode) async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        _logger.e('No active profile found');
        return false;
      }
      
      final token = await _traktClient.auth.requestAccessToken(
        redirectUri: AppConfig.traktRedirectUri,
        code: authCode,
      );
      
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        token.createdAt * 1000,
      ).add(Duration(seconds: token.expiresIn));
      
      // Set the auth token BEFORE making authenticated API calls
      _traktClient.setAuthToken(token.accessToken);
      
      final userSettings = await _traktClient.users.getSettings();
      
      final updatedProfile = profile.copyWith(
        traktAccessToken: token.accessToken,
        traktRefreshToken: token.refreshToken,
        traktTokenExpiry: expiryDate,
        traktUsername: userSettings.user?.username,
      );
      
      await _profileService.updateProfile(updatedProfile);
      
      _logger.i('Trakt connected successfully for ${userSettings.user?.username}');
      return true;
    } catch (e) {
      _logger.e('Failed to connect Trakt: $e');
      return false;
    }
  }
  
  Future<bool> disconnectTrakt() async {
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null || !profile.isTraktConnected) {
        return false;
      }
      
      if (profile.traktAccessToken != null) {
        try {
          await _traktClient.auth.revokeToken(profile.traktAccessToken!);
        } catch (e) {
          _logger.w('Failed to revoke token: $e');
        }
      }
      
      final updatedProfile = profile.disconnectTrakt();
      await _profileService.updateProfile(updatedProfile);
      _traktClient.removeAuthToken();
      
      _logger.i('Trakt disconnected successfully');
      return true;
    } catch (e) {
      _logger.e('Failed to disconnect Trakt: $e');
      return false;
    }
  }

  
  Future<bool> _ensureValidToken() async {
    final profile = await _profileService.getCurrentProfile();
    if (profile == null || !profile.isTraktConnected) {
      _logger.w('No Trakt connection found');
      return false;
    }
    
    if (!profile.isTraktTokenExpired) {
      _traktClient.setAuthToken(profile.traktAccessToken!);
      return true;
    }
    
    try {
      _logger.i('Refreshing Trakt token');
      final token = await _traktClient.auth.refreshAccessToken(
        redirectUri: AppConfig.traktRedirectUri,
        refreshToken: profile.traktRefreshToken!,
      );
      
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        token.createdAt * 1000,
      ).add(Duration(seconds: token.expiresIn));
      
      final updatedProfile = profile.copyWith(
        traktAccessToken: token.accessToken,
        traktRefreshToken: token.refreshToken,
        traktTokenExpiry: expiryDate,
      );
      
      await _profileService.updateProfile(updatedProfile);
      _traktClient.setAuthToken(token.accessToken);
      
      return true;
    } catch (e) {
      _logger.e('Failed to refresh token: $e');
      return false;
    }
  }
  
  Future<TraktSyncResult> syncAll() async {
    if (_isSyncing) {
      _logger.w('Sync already in progress');
      return TraktSyncResult(
        success: false,
        message: 'Sync already in progress',
      );
    }
    
    _isSyncing = true;
    
    try {
      if (!await _ensureValidToken()) {
        return TraktSyncResult(
          success: false,
          message: 'Not connected to Trakt or token expired',
        );
      }
      
      final watchedMovies = await getWatchedMovies();
      final watchedShows = await getWatchedShows();
      final watchlistMovies = await getWatchlistMovies();
      final watchlistShows = await getWatchlistShows();
      
      final profile = await _profileService.getCurrentProfile();
      if (profile != null) {
        await _profileService.updateProfile(
          profile.copyWith(lastTraktSync: DateTime.now()),
        );
      }
      
      _logger.i('Sync completed successfully');
      return TraktSyncResult(
        success: true,
        message: 'Sync completed',
        watchedMoviesCount: watchedMovies.length,
        watchedShowsCount: watchedShows.length,
        watchlistMoviesCount: watchlistMovies.length,
        watchlistShowsCount: watchlistShows.length,
      );
    } catch (e) {
      _logger.e('Sync failed: $e');
      return TraktSyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<List<TraktMediaItem>> getWatchedMovies() async {
    if (!await _ensureValidToken()) return [];
    
    try {
      return await _traktClient.sync.getWatchedMovies(
        extended: TraktExtended.full,
      );
    } catch (e) {
      _logger.e('Failed to get watched movies: $e');
      return [];
    }
  }
  
  Future<List<TraktMediaItem>> getWatchedShows() async {
    if (!await _ensureValidToken()) return [];
    
    try {
      return await _traktClient.sync.getWatchedShows(
        extended: TraktExtended.full,
      );
    } catch (e) {
      _logger.e('Failed to get watched shows: $e');
      return [];
    }
  }
  
  Future<List<TraktMediaItem>> getWatchlistMovies() async {
    if (!await _ensureValidToken()) return [];
    
    try {
      return await _traktClient.sync.getWatchlistMovies(
        extended: TraktExtended.full,
      );
    } catch (e) {
      _logger.e('Failed to get watchlist movies: $e');
      return [];
    }
  }
  
  Future<List<TraktMediaItem>> getWatchlistShows() async {
    if (!await _ensureValidToken()) return [];
    
    try {
      return await _traktClient.sync.getWatchlistShows(
        extended: TraktExtended.full,
      );
    } catch (e) {
      _logger.e('Failed to get watchlist shows: $e');
      return [];
    }
  }
  
  Future<bool> addToWatchlist({
    List<TraktMovie>? movies,
    List<TraktShow>? shows,
  }) async {
    if (!await _ensureValidToken()) return false;
    
    try {
      final items = TraktSyncItems(
        movies: movies,
        shows: shows,
      );
      
      final response = await _traktClient.sync.addToWatchlist(items);
      _logger.i('Added to watchlist: ${response.added?.movies ?? 0} movies, ${response.added?.shows ?? 0} shows');
      return true;
    } catch (e) {
      _logger.e('Failed to add to watchlist: $e');
      return false;
    }
  }
  
  Future<bool> removeFromWatchlist({
    List<TraktMovie>? movies,
    List<TraktShow>? shows,
  }) async {
    if (!await _ensureValidToken()) return false;
    
    try {
      final items = TraktSyncItems(
        movies: movies,
        shows: shows,
      );
      
      final response = await _traktClient.sync.removeFromWatchlist(items);
      _logger.i('Removed from watchlist: ${response.deleted?.movies ?? 0} movies, ${response.deleted?.shows ?? 0} shows');
      return true;
    } catch (e) {
      _logger.e('Failed to remove from watchlist: $e');
      return false;
    }
  }
  
  Future<bool> markAsWatched({
    List<TraktMovie>? movies,
    List<TraktShow>? shows,
  }) async {
    if (!await _ensureValidToken()) return false;
    
    try {
      final items = TraktSyncItems(
        movies: movies,
        shows: shows,
      );
      
      final response = await _traktClient.sync.addWatchedHistory(items);
      _logger.i('Marked as watched: ${response.added?.movies ?? 0} movies, ${response.added?.shows ?? 0} shows');
      return true;
    } catch (e) {
      _logger.e('Failed to mark as watched: $e');
      return false;
    }
  }
  
  Future<bool> removeFromWatched({
    List<TraktMovie>? movies,
    List<TraktShow>? shows,
  }) async {
    if (!await _ensureValidToken()) return false;
    
    try {
      final items = TraktSyncItems(
        movies: movies,
        shows: shows,
      );
      
      final response = await _traktClient.sync.removeWatchedHistory(items);
      _logger.i('Removed from watched: ${response.deleted?.movies ?? 0} movies, ${response.deleted?.shows ?? 0} shows');
      return true;
    } catch (e) {
      _logger.e('Failed to remove from watched: $e');
      return false;
    }
  }
  
  bool get isSyncing => _isSyncing;
}

class TraktSyncResult {
  final bool success;
  final String message;
  final int? watchedMoviesCount;
  final int? watchedShowsCount;
  final int? watchlistMoviesCount;
  final int? watchlistShowsCount;
  
  TraktSyncResult({
    required this.success,
    required this.message,
    this.watchedMoviesCount,
    this.watchedShowsCount,
    this.watchlistMoviesCount,
    this.watchlistShowsCount,
  });
}
