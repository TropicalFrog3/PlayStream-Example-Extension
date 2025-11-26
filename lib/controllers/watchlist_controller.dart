import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trakt/trakt_sync.dart';
import '../models/trakt/trakt_movie.dart';
import '../models/trakt/trakt_show.dart';
import '../services/trakt/trakt_client.dart';
import '../services/profile_service.dart';
import '../core/config/trakt_config.dart';

final watchlistMoviesProvider = FutureProvider.autoDispose<List<TraktMediaItem>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  final client = ref.watch(traktClientProvider);
  client.setAuthToken(profile.traktAccessToken!);
  
  return await client.sync.getWatchlistMovies(extended: TraktExtended.full);
});

final watchlistShowsProvider = FutureProvider.autoDispose<List<TraktMediaItem>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  final client = ref.watch(traktClientProvider);
  client.setAuthToken(profile.traktAccessToken!);
  
  return await client.sync.getWatchlistShows(extended: TraktExtended.full);
});

final watchedMoviesProvider = FutureProvider.autoDispose<List<TraktMediaItem>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  final client = ref.watch(traktClientProvider);
  client.setAuthToken(profile.traktAccessToken!);
  
  return await client.sync.getWatchedMovies(extended: TraktExtended.full);
});

final watchedShowsProvider = FutureProvider.autoDispose<List<TraktMediaItem>>((ref) async {
  final profileService = ref.watch(profileServiceProvider);
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  final client = ref.watch(traktClientProvider);
  client.setAuthToken(profile.traktAccessToken!);
  
  return await client.sync.getWatchedShows(extended: TraktExtended.full);
});

final watchlistControllerProvider = Provider<WatchlistController>((ref) {
  return WatchlistController(ref);
});

class WatchlistController {
  final Ref _ref;
  
  WatchlistController(this._ref);
  
  Future<void> addMovieToWatchlist(TraktMovie movie) async {
    final profileService = _ref.read(profileServiceProvider);
    final profile = await profileService.getCurrentProfile();
    
    if (profile == null || !profile.isTraktConnected) {
      throw Exception('Not connected to Trakt');
    }
    
    final client = _ref.read(traktClientProvider);
    client.setAuthToken(profile.traktAccessToken!);
    
    final items = TraktSyncItems(movies: [movie]);
    await client.sync.addToWatchlist(items);
    
    // Refresh the watchlist
    _ref.invalidate(watchlistMoviesProvider);
  }
  
  Future<void> removeMovieFromWatchlist(TraktMovie movie) async {
    final profileService = _ref.read(profileServiceProvider);
    final profile = await profileService.getCurrentProfile();
    
    if (profile == null || !profile.isTraktConnected) {
      throw Exception('Not connected to Trakt');
    }
    
    final client = _ref.read(traktClientProvider);
    client.setAuthToken(profile.traktAccessToken!);
    
    final items = TraktSyncItems(movies: [movie]);
    await client.sync.removeFromWatchlist(items);
    
    // Refresh the watchlist
    _ref.invalidate(watchlistMoviesProvider);
  }
  
  Future<void> markMovieAsWatched(TraktMovie movie) async {
    final profileService = _ref.read(profileServiceProvider);
    final profile = await profileService.getCurrentProfile();
    
    if (profile == null || !profile.isTraktConnected) {
      throw Exception('Not connected to Trakt');
    }
    
    final client = _ref.read(traktClientProvider);
    client.setAuthToken(profile.traktAccessToken!);
    
    final items = TraktSyncItems(movies: [movie]);
    await client.sync.addWatchedHistory(items);
    
    // Refresh the watched list
    _ref.invalidate(watchedMoviesProvider);
  }
  
  Future<void> addShowToWatchlist(TraktShow show) async {
    final profileService = _ref.read(profileServiceProvider);
    final profile = await profileService.getCurrentProfile();
    
    if (profile == null || !profile.isTraktConnected) {
      throw Exception('Not connected to Trakt');
    }
    
    final client = _ref.read(traktClientProvider);
    client.setAuthToken(profile.traktAccessToken!);
    
    final items = TraktSyncItems(shows: [show]);
    await client.sync.addToWatchlist(items);
    
    // Refresh the watchlist
    _ref.invalidate(watchlistShowsProvider);
  }
  
  Future<void> removeShowFromWatchlist(TraktShow show) async {
    final profileService = _ref.read(profileServiceProvider);
    final profile = await profileService.getCurrentProfile();
    
    if (profile == null || !profile.isTraktConnected) {
      throw Exception('Not connected to Trakt');
    }
    
    final client = _ref.read(traktClientProvider);
    client.setAuthToken(profile.traktAccessToken!);
    
    final items = TraktSyncItems(shows: [show]);
    await client.sync.removeFromWatchlist(items);
    
    // Refresh the watchlist
    _ref.invalidate(watchlistShowsProvider);
  }
}

final traktClientProvider = Provider<TraktClient>((ref) {
  return TraktClient();
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService.instance;
});
