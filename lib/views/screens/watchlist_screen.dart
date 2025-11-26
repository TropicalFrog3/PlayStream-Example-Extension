import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playstream/views/widgets/show_card.dart';
import '../../controllers/watchlist_controller.dart';


class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistMovies = ref.watch(watchlistMoviesProvider);
    final watchlistShows = ref.watch(watchlistShowsProvider);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Watchlist'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Movies'),
              Tab(text: 'Shows'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Movies tab
            watchlistMovies.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No movies in watchlist'),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final movie = items[index].movie;
                    if (movie == null) return const SizedBox.shrink();
                    return ShowCard(media: movie, isMovie: true);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
            
            // Shows tab
            watchlistShows.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No shows in watchlist'),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final show = items[index].show;
                    if (show == null) return const SizedBox.shrink();
                    return ShowCard(media: show, isMovie: false);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }
}
