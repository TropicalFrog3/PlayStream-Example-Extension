import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playstream/models/trakt/trakt_movie.dart';
import '../../controllers/movie_controller.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/show_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final myAiringShows = ref.watch(myAiringShowsProvider);
    final myNewShows = ref.watch(myNewShowsProvider);
    final mySeasonPremieres = ref.watch(mySeasonPremieresProvider);
    final myFinales = ref.watch(myFinalesProvider);
    final myMovies = ref.watch(myMoviesProvider);
    final recommendedMovies = ref.watch(recommendedMoviesProvider);
    final recommendedShows = ref.watch(recommendedShowsProvider);
    final allNewShows = ref.watch(allNewShowsProvider);
    final recentlyUpdatedMovies = ref.watch(recentlyUpdatedMoviesProvider);
    final trendingLists = ref.watch(trendingListsProvider);
    final popularLists = ref.watch(popularListsProvider);
    final trendingMovies = ref.watch(trendingMoviesProvider);
    final trendingShows = ref.watch(trendingShowsProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final popularShows = ref.watch(popularShowsProvider);
    final anticipatedMovies = ref.watch(anticipatedMoviesProvider);
    final anticipatedShows = ref.watch(anticipatedShowsProvider);
    final watchedMovies = ref.watch(watchedMoviesProvider);
    final watchedShows = ref.watch(watchedShowsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.black,
            title: const Text(
              'Discover',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () => context.push('/search'),
              ),
              if (user != null) ...[
                if (user.isAdmin)
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings,
                        color: Colors.white),
                    onPressed: () => context.push('/admin'),
                  ),
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  onPressed: () => context.push('/profile'),
                ),
              ] else
                TextButton(
                  onPressed: () => context.push('/login'),
                  child: const Text('Login',
                      style: TextStyle(color: Colors.white)),
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ..._buildSections([
                  _buildMyAiringShowsSection(context, myAiringShows),
                  // _buildMyNewShowsSection(context, myNewShows),
                  // _buildMySeasonPremieresSection(context, mySeasonPremieres),
                  // _buildMyFinalesSection(context, myFinales),
                  // _buildMyMoviesSection(context, myMovies),
                  _buildRecommendedMediaSection(context, recommendedMovies, recommendedShows),
                  _buildTrendingMediaSection(context, trendingMovies, trendingShows),
                  _buildPopularMediaSection(context, popularMovies, popularShows),
                  _buildAnticipatedMediaSection(context, anticipatedMovies, anticipatedShows),
                  _buildMostWatchedMediaSection(context, watchedMovies, watchedShows),
                  // _buildAllNewMediaSection(context, recentlyUpdatedMovies, allNewShows),
                  _buildCommunityListsSection(context, trendingLists, popularLists),
                ]),
                const SizedBox(height: 16), // Bottom padding for nav bar
              ],
            ),
          ),
        ],
        ),
        bottomNavigationBar: const AppBottomNavBar(currentRoute: '/home'),
      ),
    );
  }

  Widget _buildTrendingSection(
    BuildContext context,
    String title,
    AsyncValue moviesAsync, {
    bool showViewAll = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, showViewAll),
        const SizedBox(height: 12),
        moviesAsync.when(
          data: (movies) {
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final trendingMovie = movies[index];
                  final movie = trendingMovie.movie;
                  if (movie == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: movie, isMovie: true),
                  );
                },
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(),
        ),
      ],
    );
  }

  Widget _buildMovieSection(
    BuildContext context,
    String title,
    AsyncValue moviesAsync, {
    bool showViewAll = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, showViewAll),
        const SizedBox(height: 12),
        moviesAsync.when(
          data: (movies) {
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: movie, isMovie: true),
                  );
                },
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(),
        ),
      ],
    );
  }

  Widget _buildAnticipatedSection(
    BuildContext context,
    String title,
    AsyncValue moviesAsync, {
    bool showViewAll = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, showViewAll),
        const SizedBox(height: 12),
        moviesAsync.when(
          data: (movies) {
            return SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final anticipatedMovie = movies[index];
                  final movie = anticipatedMovie.movie;
                  if (movie == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: movie, isMovie: true),
                  );
                },
              ),
            );
          },
          loading: () => _buildLoadingState(),
          error: (e, _) => _buildErrorState(),
        ),
      ],
    );
  }

  List<Widget> _buildSections(List<Widget> sections) {
    final List<Widget> result = [];
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      // Only add the section if it's not a SizedBox.shrink()
      if (section is! SizedBox || (section.width != 0.0 && section.height != 0.0)) {
        if (result.isNotEmpty) {
          result.add(const SizedBox(height: 24));
        }
        result.add(section);
      }
    }
    return result;
  }

  Widget _buildSectionHeader(String title, bool showViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (showViewAll)
            TextButton(
              onPressed: () {
                // Navigate to category view
              },
              child: const Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 220,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
      ),
    );
  }

  Widget _buildErrorState() {
    return const SizedBox(
      height: 220,
      child: Center(
        child: Text(
          'Error loading content',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildMyAiringShowsSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> airingShowsAsync) {
    return airingShowsAsync.when(
      data: (shows) {
        if (shows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.live_tv, color: Color(0xFF6C63FF), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Airing Shows',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shows.length > 10 ? 10 : shows.length,
                itemBuilder: (context, index) {
                  final item = shows[index];
                  final show = item['show'];
                  final episode = item['episode'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: show, isMovie: false, episode: episode),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMyNewShowsSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> newShowsAsync) {
    return newShowsAsync.when(
      data: (shows) {
        if (shows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.new_releases, color: Color(0xFF6C63FF), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My New Shows',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shows.length > 10 ? 10 : shows.length,
                itemBuilder: (context, index) {
                  final item = shows[index];
                  final show = item['show'];
                  final episode = item['episode'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: show, isMovie: false, episode: episode),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMySeasonPremieresSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> premieresAsync) {
    return premieresAsync.when(
      data: (shows) {
        if (shows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFF6C63FF), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Season Premieres',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shows.length > 10 ? 10 : shows.length,
                itemBuilder: (context, index) {
                  final item = shows[index];
                  final show = item['show'];
                  final episode = item['episode'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: show, isMovie: false, episode: episode),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMyFinalesSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> finalesAsync) {
    return finalesAsync.when(
      data: (shows) {
        if (shows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Finales',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shows.length > 10 ? 10 : shows.length,
                itemBuilder: (context, index) {
                  final item = shows[index];
                  final show = item['show'];
                  final episode = item['episode'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: show, isMovie: false, episode: episode),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMyMoviesSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> moviesAsync) {
    return moviesAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.movie_filter, color: Color(0xFF6C63FF), size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Movies',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length > 10 ? 10 : movies.length,
                itemBuilder: (context, index) {
                  final item = movies[index];
                  final movie = item['movie'];
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShowCard(media: movie, isMovie: true),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecommendedMediaSection(
    BuildContext context,
    AsyncValue<List<TraktMovie>> moviesAsync,
    AsyncValue<List<Map<String, dynamic>>> showsAsync,
  ) {
    // Check if both are empty
    final hasMovies = moviesAsync.value?.isNotEmpty ?? false;
    final hasShows = showsAsync.value?.isNotEmpty ?? false;
    
    if (!hasMovies && !hasShows) {
      return const SizedBox.shrink();
    }

    return _RecommendedMediaWidget(
      moviesAsync: moviesAsync,
      showsAsync: showsAsync,
      homeScreen: this,
    );
  }

  Widget _buildTrendingMediaSection(
    BuildContext context,
    AsyncValue<List<TraktTrendingMovie>> moviesAsync,
    AsyncValue<List<Map<String, dynamic>>> showsAsync,
  ) {
    return _TrendingMediaWidget(
      moviesAsync: moviesAsync,
      showsAsync: showsAsync,
      homeScreen: this,
    );
  }

  Widget _buildPopularMediaSection(
    BuildContext context,
    AsyncValue<List<TraktMovie>> moviesAsync,
    AsyncValue<List<Map<String, dynamic>>> showsAsync,
  ) {
    return _PopularMediaWidget(
      moviesAsync: moviesAsync,
      showsAsync: showsAsync,
      homeScreen: this,
    );
  }

  Widget _buildAnticipatedMediaSection(
    BuildContext context,
    AsyncValue<List<TraktAnticipatedMovie>> moviesAsync,
    AsyncValue<List<Map<String, dynamic>>> showsAsync,
  ) {
    return _AnticipatedMediaWidget(
      moviesAsync: moviesAsync,
      showsAsync: showsAsync,
      homeScreen: this,
    );
  }

  Widget _buildMostWatchedMediaSection(
    BuildContext context,
    AsyncValue<List<TraktMovie>> moviesAsync,
    AsyncValue<List<Map<String, dynamic>>> showsAsync,
  ) {
    return _MostWatchedMediaWidget(
      moviesAsync: moviesAsync,
      showsAsync: showsAsync,
      homeScreen: this,
    );
  }

  Widget _buildAllNewMediaSection(
    BuildContext context,
    AsyncValue<List<TraktMovie>> newMoviesAsync,
    AsyncValue<List<Map<String, dynamic>>> newShowsAsync,
  ) {
    // Check if both are empty
    final hasMovies = newMoviesAsync.value?.isNotEmpty ?? false;
    final hasShows = newShowsAsync.value?.isNotEmpty ?? false;
    
    if (!hasMovies && !hasShows) {
      return const SizedBox.shrink();
    }

    return _AllNewMediaWidget(
      newMoviesAsync: newMoviesAsync,
      newShowsAsync: newShowsAsync,
      homeScreen: this,
    );
  }
  
  Widget _buildCommunityListsSection(
    BuildContext context,
    AsyncValue trendingListsAsync,
    AsyncValue popularListsAsync,
  ) {
    // Check if both are empty
    final hasTrending = trendingListsAsync.value?.isNotEmpty ?? false;
    final hasPopular = popularListsAsync.value?.isNotEmpty ?? false;
    
    if (!hasTrending && !hasPopular) {
      return const SizedBox.shrink();
    }

    return _CommunityListsWidget(
      trendingListsAsync: trendingListsAsync,
      popularListsAsync: popularListsAsync,
      homeScreen: this,
    );
  }

  Widget _buildListCard(BuildContext context, dynamic list, int likeCount) {
    return GestureDetector(
      onTap: () {
        context.push('/list', extra: list);
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                list.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (list.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  list.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                list.user.username,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Icon(Icons.favorite, size: 14, color: Colors.red[300]),
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.list, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${list.itemCount}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

}

class _CommunityListsWidget extends StatefulWidget {
  final AsyncValue trendingListsAsync;
  final AsyncValue popularListsAsync;
  final HomeScreen homeScreen;

  const _CommunityListsWidget({
    required this.trendingListsAsync,
    required this.popularListsAsync,
    required this.homeScreen,
  });

  @override
  State<_CommunityListsWidget> createState() => _CommunityListsWidgetState();
}

class _CommunityListsWidgetState extends State<_CommunityListsWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.list_alt, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Community Lists',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Trending', 0),
              const SizedBox(width: 8),
              _buildTabButton('Popular', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.trendingListsAsync.when(
            data: (lists) {
              if (lists.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lists.length > 10 ? 10 : lists.length,
                  itemBuilder: (context, index) {
                    final trendingList = lists[index];
                    final list = trendingList.list;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: widget.homeScreen._buildListCard(context, list, trendingList.likeCount),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.popularListsAsync.when(
            data: (lists) {
              if (lists.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: lists.length > 10 ? 10 : lists.length,
                  itemBuilder: (context, index) {
                    final trendingList = lists[index];
                    final list = trendingList.list;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: widget.homeScreen._buildListCard(context, list, trendingList.likeCount),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RecommendedMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktMovie>> moviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> showsAsync;
  final HomeScreen homeScreen;

  const _RecommendedMediaWidget({
    required this.moviesAsync,
    required this.showsAsync,
    required this.homeScreen,
  });

  @override
  State<_RecommendedMediaWidget> createState() => _RecommendedMediaWidgetState();
}

class _RecommendedMediaWidgetState extends State<_RecommendedMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.recommend, color: Color(0xFF6C63FF), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Recommended for You',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.moviesAsync.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length > 10 ? 10 : movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.showsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final show = shows[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _TrendingMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktTrendingMovie>> moviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> showsAsync;
  final HomeScreen homeScreen;

  const _TrendingMediaWidget({
    required this.moviesAsync,
    required this.showsAsync,
    required this.homeScreen,
  });

  @override
  State<_TrendingMediaWidget> createState() => _TrendingMediaWidgetState();
}

class _TrendingMediaWidgetState extends State<_TrendingMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: Color(0xFF6C63FF), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Trending Now',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.moviesAsync.when(
            data: (trendingMovies) {
              if (trendingMovies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: trendingMovies.length > 10 ? 10 : trendingMovies.length,
                  itemBuilder: (context, index) {
                    final trendingMovie = trendingMovies[index];
                    final movie = trendingMovie.movie;
                    if (movie == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.showsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final item = shows[index];
                    final show = item['show'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PopularMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktMovie>> moviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> showsAsync;
  final HomeScreen homeScreen;

  const _PopularMediaWidget({
    required this.moviesAsync,
    required this.showsAsync,
    required this.homeScreen,
  });

  @override
  State<_PopularMediaWidget> createState() => _PopularMediaWidgetState();
}

class _PopularMediaWidgetState extends State<_PopularMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Popular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.moviesAsync.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length > 10 ? 10 : movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.showsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final item = shows[index];
                    final show = item['show'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AnticipatedMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktAnticipatedMovie>> moviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> showsAsync;
  final HomeScreen homeScreen;

  const _AnticipatedMediaWidget({
    required this.moviesAsync,
    required this.showsAsync,
    required this.homeScreen,
  });

  @override
  State<_AnticipatedMediaWidget> createState() => _AnticipatedMediaWidgetState();
}

class _AnticipatedMediaWidgetState extends State<_AnticipatedMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.upcoming, color: Color(0xFF6C63FF), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Anticipated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.moviesAsync.when(
            data: (anticipatedMovies) {
              if (anticipatedMovies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: anticipatedMovies.length > 10 ? 10 : anticipatedMovies.length,
                  itemBuilder: (context, index) {
                    final anticipatedMovie = anticipatedMovies[index];
                    final movie = anticipatedMovie.movie;
                    if (movie == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.showsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final item = shows[index];
                    final show = item['show'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MostWatchedMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktMovie>> moviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> showsAsync;
  final HomeScreen homeScreen;

  const _MostWatchedMediaWidget({
    required this.moviesAsync,
    required this.showsAsync,
    required this.homeScreen,
  });

  @override
  State<_MostWatchedMediaWidget> createState() => _MostWatchedMediaWidgetState();
}

class _MostWatchedMediaWidgetState extends State<_MostWatchedMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.visibility, color: Color(0xFF6C63FF), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Most Watched',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.moviesAsync.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length > 10 ? 10 : movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.showsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final item = shows[index];
                    final show = item['show'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _AllNewMediaWidget extends StatefulWidget {
  final AsyncValue<List<TraktMovie>> newMoviesAsync;
  final AsyncValue<List<Map<String, dynamic>>> newShowsAsync;
  final HomeScreen homeScreen;

  const _AllNewMediaWidget({
    required this.newMoviesAsync,
    required this.newShowsAsync,
    required this.homeScreen,
  });

  @override
  State<_AllNewMediaWidget> createState() => _AllNewMediaWidgetState();
}

class _AllNewMediaWidgetState extends State<_AllNewMediaWidget> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.fiber_new, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              const Text(
                'All New Releases',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tab buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTabButton('Movies', 0),
              const SizedBox(width: 8),
              _buildTabButton('Shows', 1),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Content
        if (_selectedTab == 0)
          widget.newMoviesAsync.when(
            data: (movies) {
              if (movies.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: movies.length > 10 ? 10 : movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: movie, isMovie: true),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          )
        else
          widget.newShowsAsync.when(
            data: (shows) {
              if (shows.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shows.length > 10 ? 10 : shows.length,
                  itemBuilder: (context, index) {
                    final item = shows[index];
                    final show = item['show'];
                    final episode = item['episode'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShowCard(media: show, isMovie: false, episode: episode),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}








