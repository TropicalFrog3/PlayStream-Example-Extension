import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/movie_controller.dart';
import '../../controllers/watchlist_controller.dart';
import '../../services/video/stream_scraper.dart';
import '../../services/extension/extension_manager.dart';
// import '../widgets/movie_card.dart';

class MovieDetailsScreen extends ConsumerWidget {
  final String slug;
  
  const MovieDetailsScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movieAsync = ref.watch(movieDetailsProvider(slug));
    final relatedMoviesAsync = ref.watch(relatedMoviesProvider(slug));
    
    return Scaffold(
      body: movieAsync.when(
        data: (movie) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(movie.title ?? ''),
                background: movie.ids?.tmdb != null
                    ? Image.network(
                        'https://image.tmdb.org/t/p/w780/backdrop.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[900],
                        ),
                      )
                    : Container(color: Colors.grey[900]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (movie.year != null)
                          Text(
                            '${movie.year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (movie.runtime != null) ...[
                          const SizedBox(width: 16),
                          Text(
                            '${movie.runtime} min',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (movie.rating != null) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            movie.rating!.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Scrape for video sources
                              final extensionManager = ref.read(extensionManagerProvider);
                              final scraper = StreamScraper(extensionManager: extensionManager);
                              final sources = await scraper.scrapeMovie(
                                title: movie.title ?? '',
                                year: movie.year,
                                imdbId: movie.ids?.imdb,
                              );
                              
                              if (sources.isNotEmpty && context.mounted) {
                                context.push('/player', extra: {
                                  'title': movie.title,
                                  'videoUrl': sources.first.url,
                                });
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No streaming sources found'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: () async {
                            try {
                              await ref.read(watchlistControllerProvider)
                                  .addMovieToWatchlist(movie);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to watchlist'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().contains('Not connected')
                                        ? 'Please connect to Trakt first'
                                        : 'Failed to add to watchlist'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (movie.overview != null) ...[
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (movie.genres != null && movie.genres!.isNotEmpty) ...[
                      Text(
                        'Genres',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: movie.genres!.map((genre) {
                          return Chip(label: Text(genre));
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text(
                      'Related Movies',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    relatedMoviesAsync.when(
                      data: (movies) => SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              // child: MovieCard(movie: movies[index]),
                            );
                          },
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
