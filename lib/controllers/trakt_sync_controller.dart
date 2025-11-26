import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/trakt/trakt_sync_service.dart';
import '../services/profile_service.dart';
import '../models/user/user_profile.dart';

final traktSyncServiceProvider = Provider<TraktSyncService>((ref) {
  return TraktSyncService.instance;
});

final currentProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final profileService = ProfileService.instance;
  await profileService.init();
  
  while (true) {
    yield await profileService.getCurrentProfile();
    await Future.delayed(const Duration(seconds: 1));
  }
});

final isTraktConnectedProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  return profileAsync.when(
    data: (profile) => profile?.isTraktConnected ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

final traktSyncStateProvider = StateNotifierProvider<TraktSyncStateNotifier, TraktSyncState>((ref) {
  return TraktSyncStateNotifier(ref);
});

class TraktSyncState {
  final bool isSyncing;
  final String? lastSyncMessage;
  final DateTime? lastSyncTime;
  final int? watchedMoviesCount;
  final int? watchedShowsCount;
  final int? watchlistMoviesCount;
  final int? watchlistShowsCount;
  
  TraktSyncState({
    this.isSyncing = false,
    this.lastSyncMessage,
    this.lastSyncTime,
    this.watchedMoviesCount,
    this.watchedShowsCount,
    this.watchlistMoviesCount,
    this.watchlistShowsCount,
  });
  
  TraktSyncState copyWith({
    bool? isSyncing,
    String? lastSyncMessage,
    DateTime? lastSyncTime,
    int? watchedMoviesCount,
    int? watchedShowsCount,
    int? watchlistMoviesCount,
    int? watchlistShowsCount,
  }) {
    return TraktSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncMessage: lastSyncMessage ?? this.lastSyncMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      watchedMoviesCount: watchedMoviesCount ?? this.watchedMoviesCount,
      watchedShowsCount: watchedShowsCount ?? this.watchedShowsCount,
      watchlistMoviesCount: watchlistMoviesCount ?? this.watchlistMoviesCount,
      watchlistShowsCount: watchlistShowsCount ?? this.watchlistShowsCount,
    );
  }
}

class TraktSyncStateNotifier extends StateNotifier<TraktSyncState> {
  final Ref ref;
  
  TraktSyncStateNotifier(this.ref) : super(TraktSyncState());
  
  Future<void> syncAll() async {
    if (state.isSyncing) return;
    
    state = state.copyWith(isSyncing: true);
    
    final syncService = ref.read(traktSyncServiceProvider);
    final result = await syncService.syncAll();
    
    state = TraktSyncState(
      isSyncing: false,
      lastSyncMessage: result.message,
      lastSyncTime: result.success ? DateTime.now() : state.lastSyncTime,
      watchedMoviesCount: result.watchedMoviesCount,
      watchedShowsCount: result.watchedShowsCount,
      watchlistMoviesCount: result.watchlistMoviesCount,
      watchlistShowsCount: result.watchlistShowsCount,
    );
  }
  
  Future<bool> connectTrakt(String authCode) async {
    final syncService = ref.read(traktSyncServiceProvider);
    return await syncService.connectTrakt(authCode);
  }
  
  Future<bool> disconnectTrakt() async {
    final syncService = ref.read(traktSyncServiceProvider);
    final success = await syncService.disconnectTrakt();
    
    if (success) {
      state = TraktSyncState();
    }
    
    return success;
  }
}
