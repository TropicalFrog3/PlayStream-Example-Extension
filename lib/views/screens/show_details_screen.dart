import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/show_controller.dart';
import '../../controllers/watchlist_controller.dart';
import '../../services/video/stream_scraper.dart';
import '../../services/extension/extension_manager.dart';

class ShowDetailsScreen extends ConsumerWidget {
  final String slug;
  
  const ShowDetailsScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(showDetailsProvider(slug));
    final watchlistController = ref.watch(watchlistControllerProvider);
    
    return Scaffold(
      body: showAsync.when(
        data: (show) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(show.title ?? ''),
                background: Container(color: Colors.grey[900]),
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
                        if (show.year != null)
                          Text(
                            '${show.year}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        if (show.rating != null) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            show.rating!.toStringAsFixed(1),
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
                              final extensionManager = ref.read(extensionManagerProvider);
                              final scraper = StreamScraper(extensionManager: extensionManager);
                              final sources = await scraper.scrapeShow(
                                title: show.title ?? '',
                                imdbId: show.ids?.imdb,
                                season: 1,
                                episode: 1,
                              );
                              
                              if (sources.isNotEmpty && context.mounted) {
                                context.push('/player', extra: {
                                  'title': show.title,
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
                        IconButton(
                          onPressed: () async {
                            try {
                              await watchlistController.addShowToWatchlist(show);
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to watchlist'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (show.overview != null) ...[
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        show.overview!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (show.genres != null && show.genres!.isNotEmpty) ...[
                      Text(
                        'Genres',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: show.genres!
                            .map((genre) => Chip(label: Text(genre)))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading show: $error'),
        ),
      ),
    );
  }
}
