import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playstream/views/widgets/show_card.dart';
import '../../models/trakt/trakt_movie.dart';
import '../../models/trakt/trakt_genre.dart';
import '../../services/trakt/trakt_client.dart';
// import '../widgets/movie_card.dart';
import '../widgets/app_bottom_nav_bar.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedGenreProvider = StateProvider<String?>((ref) => null);

final movieGenresProvider = FutureProvider<List<TraktGenre>>((ref) async {
  final client = TraktClient();
  return await client.genres.getMovieGenres();
});

final searchResultsProvider = FutureProvider.autoDispose<List<TraktMovie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final selectedGenre = ref.watch(selectedGenreProvider);
  
  if (query.isEmpty && selectedGenre == null) {
    return [];
  }
  
  final client = TraktClient();
  
  if (query.isNotEmpty) {
    return await client.search.searchMovies(query: query, limit: 50);
  }
  
  // If only genre is selected, get popular movies (we'll filter client-side)
  final movies = await client.movies.getPopular(limit: 50);
  
  if (selectedGenre != null) {
    return movies.where((movie) {
      return movie.genres?.any((genre) => 
        genre.toLowerCase() == selectedGenre.toLowerCase()
      ) ?? false;
    }).toList();
  }
  
  return movies;
});

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final genres = ref.watch(movieGenresProvider);
    final selectedGenre = ref.watch(selectedGenreProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search movies and shows...',
            border: InputBorder.none,
          ),
          onSubmitted: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ref.read(searchQueryProvider.notifier).state = _searchController.text;
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showGenreFilter(context, ref, genres);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Genre filter chip
          if (selectedGenre != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(selectedGenre),
                    onDeleted: () {
                      ref.read(selectedGenreProvider.notifier).state = null;
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          // Search results
          Expanded(
            child: searchResults.when(
        data: (movies) {
          if (movies.isEmpty) {
            return const Center(
              child: Text('No results found'),
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
            itemCount: movies.length,
            itemBuilder: (context, index) {
              return ShowCard(media: movies[index]);
            },
          );
        },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/search'),
    );
  }

  void _showGenreFilter(BuildContext context, WidgetRef ref, AsyncValue<List<TraktGenre>> genresAsync) {
    genresAsync.when(
      data: (genres) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Genre',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: genres.length,
                    itemBuilder: (context, index) {
                      final genre = genres[index];
                      final isSelected = ref.watch(selectedGenreProvider) == genre.slug;
                      
                      return FilterChip(
                        label: Text(
                          genre.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(selectedGenreProvider.notifier).state = 
                              selected ? genre.slug : null;
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading genres...')),
        );
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading genres: $error')),
        );
      },
    );
  }
}
