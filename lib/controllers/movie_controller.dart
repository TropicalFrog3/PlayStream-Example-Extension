import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trakt/trakt_movie.dart';
import '../services/trakt/trakt_client.dart';
import '../services/profile_service.dart';
import '../core/config/trakt_config.dart';

final traktClientProvider = Provider<TraktClient>((ref) {
  return TraktClient();
});

final trendingMoviesProvider = FutureProvider.autoDispose<List<TraktTrendingMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getTrending(
    page: 1,
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final trendingShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  try {
    final shows = await client.shows.getTrending(
      page: 1,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
    // Convert to Map format for consistency
    return shows.map((show) => {
      'show': show,
    }).toList();
  } catch (e) {
    return [];
  }
});

final popularMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getPopular(
    page: 1,
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final popularShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  try {
    final shows = await client.shows.getPopular(
      page: 1,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
    return shows.map((show) => {
      'show': show,
    }).toList();
  } catch (e) {
    return [];
  }
});

final anticipatedMoviesProvider = FutureProvider.autoDispose<List<TraktAnticipatedMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getAnticipated(
    page: 1,
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final anticipatedShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  try {
    final shows = await client.shows.getAnticipated(
      page: 1,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
    return shows.map((show) => {
      'show': show,
    }).toList();
  } catch (e) {
    return [];
  }
});

final watchedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getWatched(
    period: 'weekly',
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final watchedShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  try {
    final shows = await client.shows.getWatched(
      period: 'weekly',
      page: 1,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
    return shows.map((show) => {
      'show': show,
    }).toList();
  } catch (e) {
    return [];
  }
});

final movieDetailsProvider = FutureProvider.autoDispose.family<TraktMovie, String>((ref, slug) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getSummary(slug, extended: TraktExtended.full);
});

final relatedMoviesProvider = FutureProvider.autoDispose.family<List<TraktMovie>, String>((ref, movieId) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getRelated(
    movieId,
    page: 1,
    limit: 10,
    extended: TraktExtended.full,
  );
});

final myAiringShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    final allEpisodes = await client.shows.getMyAiringShows(days: 7);
    
    // Group episodes by show and keep only the latest episode per show
    final Map<int, Map<String, dynamic>> latestByShow = {};
    
    for (final item in allEpisodes) {
      final show = item['show'];
      final episode = item['episode'];
      final showId = show?['ids']?['trakt'];
      
      if (showId != null && episode != null) {
        final season = episode['season'] as int?;
        final episodeNumber = episode['number'] as int?;
        
        if (!latestByShow.containsKey(showId)) {
          latestByShow[showId] = item;
        } else {
          // Compare season and episode numbers to keep the latest episode
          final existingEpisode = latestByShow[showId]!['episode'];
          final existingSeason = existingEpisode?['season'] as int?;
          final existingNumber = existingEpisode?['number'] as int?;
          
          if (season != null && episodeNumber != null && 
              existingSeason != null && existingNumber != null) {
            // Compare season first, then episode number
            if (season > existingSeason || 
                (season == existingSeason && episodeNumber > existingNumber)) {
              latestByShow[showId] = item;
            }
          }
        }
      }
    }
    
    return latestByShow.values.toList();
  } catch (e) {
    return [];
  }
});

final myNewShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    return await client.shows.getMyNewShows(days: 7);
  } catch (e) {
    return [];
  }
});

final mySeasonPremieresProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    return await client.shows.getMySeasonPremieres(days: 7);
  } catch (e) {
    return [];
  }
});

final myFinalesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    return await client.shows.getMyFinales(days: 7);
  } catch (e) {
    return [];
  }
});

final myMoviesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    return await client.movies.getMyMovies(days: 7);
  } catch (e) {
    return [];
  }
});

final allNewShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  
  try {
    return await client.shows.getAllNewShows(days: 7);
  } catch (e) {
    return [];
  }
});

final recentlyUpdatedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getRecentlyUpdatedMovies(limit: 20);
});

final trendingListsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(traktClientProvider);
  
  try {
    return await client.lists.getTrendingLists(limit: 10);
  } catch (e) {
    return [];
  }
});

final popularListsProvider = FutureProvider.autoDispose((ref) async {
  final client = ref.watch(traktClientProvider);
  
  try {
    return await client.lists.getPopularLists(limit: 10);
  } catch (e) {
    return [];
  }
});

final favoritedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getFavorited(
    period: 'weekly',
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final playedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getPlayed(
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final collectedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  return await client.movies.getCollected(
    period: 'weekly',
    limit: 20,
    extended: TraktExtended.fullImages,
  );
});

final recommendedMoviesProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    return await client.recommendations.getMovieRecommendations(
      ignoreWatchlisted: false,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
  } catch (e) {
    return [];
  }
});

final recommendedShowsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(traktClientProvider);
  final profileService = ProfileService.instance;
  final profile = await profileService.getCurrentProfile();
  
  if (profile == null || !profile.isTraktConnected) {
    return [];
  }
  
  client.setAuthToken(profile.traktAccessToken!);
  
  try {
    final shows = await client.recommendations.getShowRecommendations(
      ignoreWatchlisted: false,
      limit: 20,
      extended: TraktExtended.fullImages,
    );
    return shows.map((show) => show as Map<String, dynamic>).toList();
  } catch (e) {
    return [];
  }
});
