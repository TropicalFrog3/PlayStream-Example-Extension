import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/cache_config.dart';
import '../../controllers/watchlist_controller.dart';
import '../../models/trakt/trakt_movie.dart';
import '../../models/trakt/trakt_show.dart';

class ShowCard extends ConsumerStatefulWidget {
  final dynamic media;
  final bool isMovie;
  final dynamic episode;

  const ShowCard({
    super.key,
    required this.media,
    this.isMovie = false,
    this.episode,
  });

  @override
  ConsumerState<ShowCard> createState() => _ShowCardState();
}

class _ShowCardState extends ConsumerState<ShowCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Handle both Map and object types
    dynamic mediaId;
    dynamic slug;
    String? title;
    dynamic traktImages;
    double? rating;
    
    if (widget.media is Map) {
      mediaId = widget.media['ids']?['trakt'] ?? widget.media['ids']?['slug'];
      slug = widget.media['ids']?['slug'];
      title = widget.media['title'];
      traktImages = widget.media['images']?['poster'];
      rating = widget.media['rating']?.toDouble();
    } else {
      mediaId = widget.media.ids?.trakt ?? widget.media.ids?.slug;
      slug = widget.media.ids?.slug;
      title = widget.media.title;
      traktImages = null;
      rating = widget.media.rating;
    }
    
    final hasTraktImage = traktImages != null && (traktImages as List).isNotEmpty;
    
    // Check if item is in watchlist
    final watchlistAsync = widget.isMovie 
        ? ref.watch(watchlistMoviesProvider)
        : ref.watch(watchlistShowsProvider);
    
    final isInWatchlist = watchlistAsync.when(
      data: (items) {
        return items.any((item) {
          if (widget.isMovie) {
            final movie = item.movie;
            if (movie == null) return false;
            return movie.ids?.trakt == mediaId;
          } else {
            final show = item.show;
            if (show == null) return false;
            return show.ids?.trakt == mediaId;
          }
        });
      },
      loading: () => false,
      error: (_, __) => false,
    );
    
    return GestureDetector(
      onTap: () {
        if (slug != null) {
          context.push(widget.isMovie ? '/movie/$slug' : '/show/$slug');
        }
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[900],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[800],
                ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    hasTraktImage
                        ? CachedNetworkImage(
                            imageUrl: 'https://${traktImages[0]}',
                            cacheManager: TraktImageCacheManager.instance,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => _buildTraktPoster(mediaId),
                          )
                        : _buildTraktPoster(mediaId),
                    // Rating badge
                    if (rating != null && rating > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Watchlist button
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleWatchlist(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isInWatchlist ? Icons.bookmark : Icons.bookmark_add,
                                  color: isInWatchlist ? const Color(0xFF6C63FF) : Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title ?? 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Episode info
            if (widget.episode != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  widget.episode is Map
                      ? 'S${widget.episode['season']}E${widget.episode['number']}'
                      : 'S${widget.episode.season}E${widget.episode.number}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWatchlist() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(watchlistControllerProvider);
      
      // Check if item is in watchlist
      final watchlistAsync = widget.isMovie 
          ? ref.read(watchlistMoviesProvider)
          : ref.read(watchlistShowsProvider);
      
      dynamic mediaId;
      if (widget.media is Map) {
        mediaId = (widget.media as Map)['ids']?['trakt'];
      } else {
        mediaId = (widget.media as dynamic).ids?.trakt;
      }
      
      final isInWatchlist = watchlistAsync.when(
        data: (items) {
          return items.any((item) {
            if (widget.isMovie) {
              final movie = item.movie;
              if (movie == null) return false;
              return movie.ids?.trakt == mediaId;
            } else {
              final show = item.show;
              if (show == null) return false;
              return show.ids?.trakt == mediaId;
            }
          });
        },
        loading: () => false,
        error: (_, __) => false,
      );
      
      if (widget.isMovie) {
        // Convert Map to TraktMovie if needed
        final movie = widget.media is Map 
            ? TraktMovie.fromJson(widget.media as Map<String, dynamic>)
            : widget.media as TraktMovie;
        
        if (isInWatchlist) {
          await controller.removeMovieFromWatchlist(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Removed from watchlist'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          await controller.addMovieToWatchlist(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to watchlist'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        // Convert Map to TraktShow if needed
        final show = widget.media is Map 
            ? TraktShow.fromJson(widget.media as Map<String, dynamic>)
            : widget.media as TraktShow;
        
        if (isInWatchlist) {
          await controller.removeShowFromWatchlist(show);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Removed from watchlist'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          await controller.addShowToWatchlist(show);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to watchlist'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTraktPoster(dynamic mediaId) {
    if (mediaId != null) {
      return FutureBuilder<String?>(
        future: widget.isMovie ? _fetchTraktMoviePoster(mediaId) : _fetchTraktShowPoster(mediaId),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CachedNetworkImage(
              imageUrl: snapshot.data!,
              cacheManager: TraktImageCacheManager.instance,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Center(
                child: Icon(
                  widget.isMovie ? Icons.movie : Icons.tv,
                  color: Colors.grey[600],
                  size: 40,
                ),
              ),
            );
          }
          return Center(
            child: Icon(
              widget.isMovie ? Icons.movie : Icons.tv,
              color: Colors.grey[600],
              size: 40,
            ),
          );
        },
      );
    }
    return Center(
      child: Icon(
        widget.isMovie ? Icons.movie : Icons.tv,
        color: Colors.grey[600],
        size: 40,
      ),
    );
  }

  Future<String?> _fetchTraktMoviePoster(dynamic movieId) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.trakt.tv/movies/$movieId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'trakt-api-version': '2',
            'trakt-api-key': 'b46d0bd0bf46bd0e0738a808c97cc31cf0b5408e8c4c1ea3e2efb4a2e5c0e2c5',
          },
        ),
        queryParameters: {
          'extended': 'full',
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      final posters = data['images']?['poster'] as List?;
      
      if (posters != null && posters.isNotEmpty) {
        return 'https://${posters[0]}';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _fetchTraktShowPoster(dynamic showId) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.trakt.tv/shows/$showId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'trakt-api-version': '2',
            'trakt-api-key': 'b46d0bd0bf46bd0e0738a808c97cc31cf0b5408e8c4c1ea3e2efb4a2e5c0e2c5',
          },
        ),
        queryParameters: {
          'extended': 'full',
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      final posters = data['images']?['poster'] as List?;
      
      if (posters != null && posters.isNotEmpty) {
        return 'https://${posters[0]}';
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
