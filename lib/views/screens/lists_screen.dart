import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playstream/views/widgets/show_card.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../../controllers/watchlist_controller.dart';
import '../../models/trakt/trakt_sync.dart';

final selectedListTabProvider = StateProvider<int>((ref) => 0);

enum ListSortOption {
  dateAdded,
  title,
  releaseDate,
  rating,
}

enum ListFilterOption {
  all,
  movies,
  shows,
}

final listSortProvider = StateProvider<ListSortOption>((ref) => ListSortOption.dateAdded);
final listFilterProvider = StateProvider<ListFilterOption>((ref) => ListFilterOption.all);

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedListTabProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'My List',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterSortDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.black,
            child: Row(
              children: [
                _buildTab(context, ref, 'Watchlist', 0, selectedTab),
                _buildTab(context, ref, 'Watching', 1, selectedTab),
                _buildTab(context, ref, 'History', 2, selectedTab),
              ],
            ),
          ),
          // Tab indicator
          Container(
            height: 2,
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: selectedTab == 0
                        ? const Color(0xFF6C63FF)
                        : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: selectedTab == 1
                        ? const Color(0xFF6C63FF)
                        : Colors.transparent,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: selectedTab == 2
                        ? const Color(0xFF6C63FF)
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildTabContent(context, ref, selectedTab),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/lists'),
    );
  }

  Widget _buildTab(
    BuildContext context,
    WidgetRef ref,
    String label,
    int index,
    int selectedTab,
  ) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(selectedListTabProvider.notifier).state = index;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, int selectedTab) {
    switch (selectedTab) {
      case 0:
        return _buildWatchlistTab(context, ref);
      case 1:
        return _buildWatchingTab(context, ref);
      case 2:
        return _buildHistoryTab(context, ref);
      default:
        return const SizedBox();
    }
  }

  Widget _buildWatchlistTab(BuildContext context, WidgetRef ref) {
    final watchlistMovies = ref.watch(watchlistMoviesProvider);
    final watchlistShows = ref.watch(watchlistShowsProvider);
    final filter = ref.watch(listFilterProvider);
    final sort = ref.watch(listSortProvider);

    return watchlistMovies.when(
      data: (movies) => watchlistShows.when(
        data: (shows) {
          List<TraktMediaItem> items = [];
          
          if (filter == ListFilterOption.all || filter == ListFilterOption.movies) {
            items.addAll(movies);
          }
          if (filter == ListFilterOption.all || filter == ListFilterOption.shows) {
            items.addAll(shows);
          }

          items = _sortItems(items, sort);

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(watchlistMoviesProvider);
                ref.invalidate(watchlistShowsProvider);
              },
              child: _buildEmptyState(
                context,
                icon: Icons.bookmark,
                iconColor: const Color(0xFF6C63FF),
                title: 'No items in Watchlist',
                message: 'Save items you want to watch later, and they\nwill show up here.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(watchlistMoviesProvider);
              ref.invalidate(watchlistShowsProvider);
            },
            child: _buildItemGrid(context, ref, items),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildErrorState(context, e.toString()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildErrorState(context, e.toString()),
    );
  }

  Widget _buildWatchingTab(BuildContext context, WidgetRef ref) {
    // Currently watching - placeholder for now
    // This would typically come from Trakt's /sync/playback endpoint
    return _buildEmptyState(
      context,
      icon: Icons.play_circle_outline,
      iconColor: Colors.orange,
      title: 'Nothing currently watching',
      message: 'Start watching something and it will\nshow up here.',
    );
  }

  Widget _buildHistoryTab(BuildContext context, WidgetRef ref) {
    final watchedMovies = ref.watch(watchedMoviesProvider);
    final watchedShows = ref.watch(watchedShowsProvider);
    final filter = ref.watch(listFilterProvider);
    final sort = ref.watch(listSortProvider);

    return watchedMovies.when(
      data: (movies) => watchedShows.when(
        data: (shows) {
          List<TraktMediaItem> items = [];
          
          if (filter == ListFilterOption.all || filter == ListFilterOption.movies) {
            items.addAll(movies);
          }
          if (filter == ListFilterOption.all || filter == ListFilterOption.shows) {
            items.addAll(shows);
          }

          items = _sortItems(items, sort);

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(watchedMoviesProvider);
                ref.invalidate(watchedShowsProvider);
              },
              child: _buildEmptyState(
                context,
                icon: Icons.check_circle_outline,
                iconColor: Colors.blue,
                title: 'No items in History',
                message: 'Mark items as watched, and they\nwill show up here.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(watchedMoviesProvider);
              ref.invalidate(watchedShowsProvider);
            },
            child: _buildItemGrid(context, ref, items),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildErrorState(context, e.toString()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => _buildErrorState(context, e.toString()),
    );
  }

  List<TraktMediaItem> _sortItems(List<TraktMediaItem> items, ListSortOption sort) {
    final sortedItems = List<TraktMediaItem>.from(items);
    
    switch (sort) {
      case ListSortOption.dateAdded:
        sortedItems.sort((a, b) {
          final aDate = a.watchedAt ?? '';
          final bDate = b.watchedAt ?? '';
          return bDate.compareTo(aDate);
        });
        break;
      case ListSortOption.title:
        sortedItems.sort((a, b) {
          final aTitle = a.movie?.title ?? a.show?.title ?? '';
          final bTitle = b.movie?.title ?? b.show?.title ?? '';
          return aTitle.compareTo(bTitle);
        });
        break;
      case ListSortOption.releaseDate:
        sortedItems.sort((a, b) {
          final aYear = a.movie?.year ?? a.show?.year ?? 0;
          final bYear = b.movie?.year ?? b.show?.year ?? 0;
          return bYear.compareTo(aYear);
        });
        break;
      case ListSortOption.rating:
        sortedItems.sort((a, b) {
          final aRating = a.movie?.rating ?? a.show?.rating ?? 0.0;
          final bRating = b.movie?.rating ?? b.show?.rating ?? 0.0;
          return bRating.compareTo(aRating);
        });
        break;
    }
    
    return sortedItems;
  }

  Widget _buildItemGrid(BuildContext context, WidgetRef ref, List<TraktMediaItem> items) {
    // Calculate crossAxisCount based on screen width to maintain 140px card width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 152).floor().clamp(2, 4); // 140 + 12 spacing
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 140 / 220, // width / total height (180 poster + 40 text)
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.movie != null) {
          return ShowCard(media: item.movie!, isMovie: true,);
        } else if (item.show != null) {
          return ShowCard(media: item.show!, isMovie: false,);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 60,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Explore button
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSortDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter by',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip(context, ref, 'All', ListFilterOption.all),
                _buildFilterChip(context, ref, 'Movies', ListFilterOption.movies),
                _buildFilterChip(context, ref, 'Shows', ListFilterOption.shows),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildSortChip(context, ref, 'Date Added', ListSortOption.dateAdded),
                _buildSortChip(context, ref, 'Title', ListSortOption.title),
                _buildSortChip(context, ref, 'Release Date', ListSortOption.releaseDate),
                _buildSortChip(context, ref, 'Rating', ListSortOption.rating),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, ListFilterOption option) {
    final currentFilter = ref.watch(listFilterProvider);
    final isSelected = currentFilter == option;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(listFilterProvider.notifier).state = option;
        Navigator.pop(context);
      },
      backgroundColor: Colors.grey[800],
      selectedColor: const Color(0xFF6C63FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSortChip(BuildContext context, WidgetRef ref, String label, ListSortOption option) {
    final currentSort = ref.watch(listSortProvider);
    final isSelected = currentSort == option;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(listSortProvider.notifier).state = option;
        Navigator.pop(context);
      },
      backgroundColor: Colors.grey[800],
      selectedColor: const Color(0xFF6C63FF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
