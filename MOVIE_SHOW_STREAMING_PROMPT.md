## Overview
Adapt the seanime anime onlinestreaming extension architecture to support movies and TV shows in the Flutter app. This involves creating a parallel system that handles movie/show metadata (TMDB/IMDB) instead of anime metadata (AniList).

---

## 1. Core Architecture Changes

### 1.1 Extension Type
- **Current**: `onlinestream_provider` (anime-focused)
- **New**: `movieshow_stream_provider` (movie/show-focused)
- Both should coexist in the extension system

### 1.2 Metadata Source Differences
| Aspect | Anime (Seanime) | Movies/Shows (Your App) |
|--------|-----------------|-------------------------|
| Primary ID | AniList ID | TMDB ID / IMDB ID |
| Secondary ID | MyAnimeList ID | IMDB ID / TMDB ID |
| Episode Structure | Absolute episode numbers | Season + Episode numbers |
| Status Values | FINISHED, RELEASING, etc. | Released, Ongoing, etc. |
| Format Values | TV, MOVIE, OVA, etc. | MOVIE, TV |

---

## 2. Data Models to Create/Modify

### 2.1 New Models Needed

#### `lib/models/extension/season_details.dart`
```dart
/// Represents a season of a TV show
class SeasonDetails {
  final String id;              // Provider's season identifier
  final int seasonNumber;       // Season number (1, 2, 3...)
  final String? title;          // Optional season title
  final int episodeCount;       // Number of episodes in season
  final String url;             // URL to season page
  
  // Constructor, fromJson, toJson, etc.
}
```

#### `lib/models/extension/show_episode_details.dart`
```dart
/// Represents an episode within a TV show season
class ShowEpisodeDetails {
  final String id;              // Provider's episode identifier
  final int seasonNumber;       // Which season (1, 2, 3...)
  final int episodeNumber;      // Episode within season (1, 2, 3...)
  final String url;             // URL to episode page
  final String? title;          // Optional episode title
  final String? thumbnail;      // Optional episode thumbnail
  
  // Constructor, fromJson, toJson, etc.
}
```

#### `lib/models/extension/movie_stream_source.dart`
```dart
/// Represents streaming sources for a movie
class MovieStreamSource {
  final String movieId;         // Provider's movie identifier
  final List<VideoSource> videoSources;
  final List<VideoSubtitle> subtitles;
  
  // Constructor, fromJson, toJson, etc.
}
```

#### `lib/models/extension/episode_stream_source.dart`
```dart
/// Represents streaming sources for a TV show episode
class EpisodeStreamSource {
  final int seasonNumber;
  final int episodeNumber;
  final List<VideoSource> videoSources;
  final List<VideoSubtitle> subtitles;
  
  // Constructor, fromJson, toJson, etc.
}
```

### 2.2 Update Existing Models

#### `lib/models/extension/search_options.dart`
Add support for movie/show search:
```dart
class SearchOptions {
  final Media media;            // Already exists
  final String query;           // Already exists
  final bool dub;               // Keep for anime
  final int? year;              // Already exists
  
  // NEW: Add these fields
  final String? mediaType;      // "movie" or "tv"
  final int? seasonNumber;      // For TV shows
  
  // Constructor, fromJson, toJson, etc.
}
```

#### `lib/models/extension/media.dart`
Already supports TMDB/IMDB - verify it has:
- `tmdbId` ✓ (already present)
- `imdbId` ✓ (already present)
- `format` ✓ (should support "MOVIE", "TV")
- `episodeCount` ✓ (for TV shows)
- `absoluteSeasonOffset` ✓ (for absolute episode numbering)

---

## 3. Extension Provider Interface

### 3.1 Create New Provider Type

#### `lib/models/extension/movieshow_stream_provider.dart`
```dart
/// Interface for movie/show streaming providers
abstract class MovieShowStreamProvider {
  /// Search for movies or TV shows
  Future<List<SearchResult>> search(SearchOptions options);
  
  /// Get available streaming servers for this provider
  List<String> getStreamServers();
  
  /// FOR MOVIES: Get streaming sources directly
  Future<MovieStreamSource> getMovieSource(
    String movieId, 
    String server
  );
  
  /// FOR TV SHOWS: Get list of seasons
  Future<List<SeasonDetails>> getSeasons(String showId);
  
  /// FOR TV SHOWS: Get episodes for a specific season
  Future<List<ShowEpisodeDetails>> getSeasonEpisodes(
    String showId, 
    int seasonNumber
  );
  
  /// FOR TV SHOWS: Get streaming sources for an episode
  Future<EpisodeStreamSource> getEpisodeSource(
    ShowEpisodeDetails episode,
    String server
  );
  
  /// Get provider settings
  MovieShowStreamSettings getSettings();
}

class MovieShowStreamSettings {
  final List<String> streamServers;
  final bool supportsMovies;
  final bool supportsTVShows;
  final bool supportsDub;
  
  // Constructor, fromJson, toJson, etc.
}
```

---

## 4. Android Native Bridge Updates

### 4.1 New Method Channel Methods

Add to `android/app/src/main/kotlin/.../ExtensionBridge.kt`:

```kotlin
// Movie streaming methods
"searchMovieShows" -> searchMovieShows(call, result)
"getMovieSource" -> getMovieSource(call, result)
"getSeasons" -> getSeasons(call, result)
"getSeasonEpisodes" -> getSeasonEpisodes(call, result)
"getEpisodeSource" -> getEpisodeSource(call, result)
```

### 4.2 New Interface

Create `IMovieShowStreamProvider.kt`:
```kotlin
interface IMovieShowStreamProvider {
    fun search(options: SearchOptions): List<SearchResult>
    fun getStreamServers(): List<String>
    
    // For movies
    fun getMovieSource(movieId: String, server: String): MovieStreamSource
    
    // For TV shows
    fun getSeasons(showId: String): List<SeasonDetails>
    fun getSeasonEpisodes(showId: String, seasonNumber: Int): List<ShowEpisodeDetails>
    fun getEpisodeSource(episode: ShowEpisodeDetails, server: String): EpisodeStreamSource
    
    fun getSettings(): MovieShowStreamSettings
}
```

---

## 5. Service Layer (Flutter)

### 5.1 Create New Service

#### `lib/services/extension/movieshow_stream_manager.dart`
Similar to the anime extension manager but for movies/shows:

```dart
class MovieShowStreamManager {
  // Cache management
  final Map<String, CacheEntry> _searchCache = {};
  final Map<String, CacheEntry> _seasonCache = {};
  final Map<String, CacheEntry> _episodeCache = {};
  final Map<String, CacheEntry> _sourceCache = {};
  
  // Search for content
  Future<List<SearchResult>> search({
    required String providerId,
    required Media media,
    required String query,
    String? mediaType,  // "movie" or "tv"
  });
  
  // Movie methods
  Future<MovieStreamSource> getMovieSource({
    required String providerId,
    required String movieId,
    required String server,
  });
  
  // TV Show methods
  Future<List<SeasonDetails>> getSeasons({
    required String providerId,
    required String showId,
  });
  
  Future<List<ShowEpisodeDetails>> getSeasonEpisodes({
    required String providerId,
    required String showId,
    required int seasonNumber,
  });
  
  Future<EpisodeStreamSource> getEpisodeSource({
    required String providerId,
    required ShowEpisodeDetails episode,
    required String server,
  });
  
  // Cache management
  void clearCache(String? providerId);
  void clearMediaCache(String tmdbId);
}
```

### 5.2 Caching Strategy

| Data Type | Cache Duration | Cache Key Format |
|-----------|----------------|------------------|
| Search Results | 5 minutes | `search_{provider}_{query}_{mediaType}` |
| Seasons List | 24 hours | `seasons_{provider}_{showId}` |
| Season Episodes | 24 hours | `episodes_{provider}_{showId}_S{season}` |
| Movie Sources | 30 minutes | `movie_{provider}_{movieId}_{server}` |
| Episode Sources | 30 minutes | `episode_{provider}_{showId}_S{season}E{episode}_{server}` |

---

## 6. Repository Pattern (Backend-like Logic)

### 6.1 Create Repository

#### `lib/repositories/movieshow_stream_repository.dart`
Handles business logic similar to seanime's `repository_actions.go`:

```dart
class MovieShowStreamRepository {
  // Automatic matching
  Future<SearchResult?> findBestMatch({
    required String providerId,
    required Media media,
    required List<String> titles,
  });
  
  // Manual mapping (save user's manual selection)
  Future<void> saveManualMapping({
    required String providerId,
    required String tmdbId,
    required String providerContentId,
  });
  
  Future<String?> getManualMapping({
    required String providerId,
    required String tmdbId,
  });
  
  // Get complete episode list for UI
  Future<List<ShowEpisodeDetails>> getAllEpisodes({
    required String providerId,
    required String showId,
  });
  
  // Fuzzy matching logic
  SearchResult? _getBestSearchResult(
    List<SearchResult> results,
    List<String> titles,
  );
}
```

---

## 7. Key Differences from Anime System

### 7.1 Episode Numbering

**Anime (Seanime)**:
- Absolute episode numbers: 1, 2, 3, ..., 100
- Single continuous sequence

**TV Shows (Your System)**:
- Season + Episode: S01E01, S01E02, S02E01, etc.
- Hierarchical structure: Show → Seasons → Episodes

### 7.2 Search Matching

**Anime**:
- Match against AniList titles (romaji, english)
- Use MAL ID as secondary identifier

**Movies/Shows**:
- Match against TMDB/IMDB titles
- Use both TMDB and IMDB IDs
- Consider release year more heavily
- Handle remakes and reboots

### 7.3 Content Types

**Anime**:
- TV, Movie, OVA, ONA, Special

**Movies/Shows**:
- Movie (single source)
- TV Show (seasons → episodes → sources)
- Miniseries (limited seasons)

---

## 8. Database Schema

### 8.1 Manual Mappings Table

```sql
CREATE TABLE movieshow_stream_mappings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_id TEXT NOT NULL,
  tmdb_id TEXT NOT NULL,
  imdb_id TEXT,
  provider_content_id TEXT NOT NULL,
  media_type TEXT NOT NULL,  -- 'movie' or 'tv'
  created_at INTEGER NOT NULL,
  UNIQUE(provider_id, tmdb_id)
);
```

### 8.2 Cache Metadata Table

```sql
CREATE TABLE movieshow_stream_cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  cache_key TEXT UNIQUE NOT NULL,
  provider_id TEXT NOT NULL,
  data TEXT NOT NULL,  -- JSON
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
```

---

## 9. UI Components Needed

### 9.1 Provider Selection
- List of installed movie/show streaming providers
- Filter by: supports movies, supports TV shows

### 9.2 Search & Match UI
- Automatic matching results
- Manual search interface
- Match confidence indicator

### 9.3 Season/Episode Selector (TV Shows)
- Season dropdown/list
- Episode grid/list within season
- Episode metadata display

### 9.4 Server Selection
- Available servers for selected content
- Server quality indicators
- Fallback server options

### 9.5 Player Integration
- Pass video sources to player
- Handle subtitles
- Track watch progress

---

## 10. Extension Development Guide

### 10.1 Example Extension Structure

```
my-movieshow-provider/
├── manifest.json
├── icon.png
└── provider.js
```

### 10.2 Example `manifest.json`

```json
{
  "id": "my-movieshow-provider",
  "name": "My Movie Provider",
  "version": "1.0.0",
  "type": "movieshow_stream_provider",
  "language": "javascript",
  "author": "Developer Name",
  "description": "Streams movies and TV shows",
  "permissions": ["network"],
  "settings": {
    "streamServers": ["server1", "server2"],
    "supportsMovies": true,
    "supportsTVShows": true,
    "supportsDub": false
  }
}
```

### 10.3 Example `provider.js`

```javascript
class MyMovieShowProvider {
  async search(options) {
    // options.media contains TMDB/IMDB data
    // options.query is the search term
    // options.mediaType is "movie" or "tv"
    
    const results = await fetch(/* ... */);
    return results.map(r => ({
      id: r.slug,
      title: r.title,
      url: r.url
    }));
  }
  
  async getMovieSource(movieId, server) {
    // Scrape movie streaming page
    return {
      movieId,
      videoSources: [/* ... */],
      subtitles: [/* ... */]
    };
  }
  
  async getSeasons(showId) {
    // Scrape show page for seasons
    return [
      { id: "s1", seasonNumber: 1, episodeCount: 10, url: "..." },
      { id: "s2", seasonNumber: 2, episodeCount: 12, url: "..." }
    ];
  }
  
  async getSeasonEpisodes(showId, seasonNumber) {
    // Scrape season page for episodes
    return [
      { id: "ep1", seasonNumber: 1, episodeNumber: 1, url: "..." },
      { id: "ep2", seasonNumber: 1, episodeNumber: 2, url: "..." }
    ];
  }
  
  async getEpisodeSource(episode, server) {
    // Scrape episode streaming page
    return {
      seasonNumber: episode.seasonNumber,
      episodeNumber: episode.episodeNumber,
      videoSources: [/* ... */],
      subtitles: [/* ... */]
    };
  }
  
  getStreamServers() {
    return ["server1", "server2"];
  }
  
  getSettings() {
    return {
      streamServers: this.getStreamServers(),
      supportsMovies: true,
      supportsTVShows: true,
      supportsDub: false
    };
  }
}
```

---

## 11. Implementation Checklist

### Phase 1: Data Models
- [ ] Create `SeasonDetails` model
- [ ] Create `ShowEpisodeDetails` model
- [ ] Create `MovieStreamSource` model
- [ ] Create `EpisodeStreamSource` model
- [ ] Update `SearchOptions` model
- [ ] Verify `Media` model supports TMDB/IMDB

### Phase 2: Native Bridge
- [ ] Create `IMovieShowStreamProvider` interface (Kotlin)
- [ ] Add method channel handlers in `ExtensionBridge`
- [ ] Create data classes for new models (Kotlin)
- [ ] Add JavaScript runtime support

### Phase 3: Flutter Service Layer
- [ ] Create `MovieShowStreamManager` service
- [ ] Implement caching logic
- [ ] Add error handling
- [ ] Create health monitoring

### Phase 4: Repository Layer
- [ ] Create `MovieShowStreamRepository`
- [ ] Implement automatic matching
- [ ] Implement manual mapping
- [ ] Add database operations

### Phase 5: Database
- [ ] Create mappings table
- [ ] Create cache table
- [ ] Add migration scripts

### Phase 6: UI Components
- [ ] Provider selection screen
- [ ] Search & match interface
- [ ] Season/episode selector
- [ ] Server selection
- [ ] Player integration

### Phase 7: Testing
- [ ] Unit tests for models
- [ ] Integration tests for services
- [ ] Test with sample extensions
- [ ] Performance testing

### Phase 8: Documentation
- [ ] Extension development guide
- [ ] API documentation
- [ ] User guide
- [ ] Example extensions

---

## 12. Key Considerations

### 12.1 Performance
- Aggressive caching to minimize network requests
- Lazy loading for seasons/episodes
- Background prefetching for next episode

### 12.2 Error Handling
- Graceful degradation when provider fails
- Retry logic with exponential backoff
- User-friendly error messages

### 12.3 Security
- Validate all extension inputs
- Sandbox JavaScript execution
- Rate limiting for network requests
- Content Security Policy

### 12.4 User Experience
- Fast search results (<2 seconds)
- Smooth season/episode navigation
- Automatic quality selection
- Resume playback support

---

## 13. Migration Path

If you have existing anime extensions:

1. **Keep anime system separate** - Don't merge, maintain parallel systems
2. **Reuse common code** - Video player, subtitle handling, caching
3. **Unified extension manager** - Single manager that handles both types
4. **Shared UI components** - Server selection, quality picker, etc.

---

## 14. Example Usage Flow

### For Movies:
1. User searches for "Inception 2010"
2. App queries TMDB for metadata
3. Extension searches provider with TMDB data
4. Extension returns search results
5. App matches best result (or user selects manually)
6. User selects server
7. Extension fetches movie sources
8. App plays video

### For TV Shows:
1. User searches for "Breaking Bad"
2. App queries TMDB for metadata
3. Extension searches provider with TMDB data
4. Extension returns search results
5. App matches best result (or user selects manually)
6. Extension fetches seasons list
7. User selects season
8. Extension fetches episodes for that season
9. User selects episode
10. User selects server
11. Extension fetches episode sources
12. App plays video

---

## 15. Testing Strategy

### 15.1 Unit Tests
- Model serialization/deserialization
- Cache expiration logic
- Matching algorithms

### 15.2 Integration Tests
- Extension loading
- Method channel communication
- Database operations

### 15.3 E2E Tests
- Complete search → play flow
- Manual mapping flow
- Error recovery

### 15.4 Performance Tests
- Cache hit rates
- Search response times
- Memory usage

---

## Summary

This implementation creates a complete movie/show streaming extension system parallel to your existing anime system. The key differences are:

1. **Metadata**: TMDB/IMDB instead of AniList
2. **Structure**: Season/Episode hierarchy instead of absolute episodes
3. **Content Types**: Movies (direct) vs TV Shows (hierarchical)
4. **Matching**: Consider release year, handle remakes

The architecture mirrors seanime's proven design while adapting to the unique requirements of movie/show streaming.
