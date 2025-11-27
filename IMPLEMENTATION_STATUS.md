# Movie/Show Streaming Extension - Implementation Status

## ✅ Completed: Phase 1 - Data Models

All new data models have been created in `lib/models/extension/`:

1. **episode_stream_source.dart** - Streaming sources for TV show episodes (S/E structure)
2. **movie_stream_source.dart** - Streaming sources for movies (direct playback)
3. **season_details.dart** - Season metadata for TV shows
4. **show_episode_details.dart** - Episode details with season/episode numbering
5. **movieshow_stream_settings.dart** - Provider settings and capabilities

### Updated Models:
- **search_options.dart** - Added `mediaType` and `seasonNumber` fields for movie/show support

## ✅ Completed: Phase 2 - Provider Interface

Created `lib/models/extension/movieshow_stream_provider.dart`:
- Abstract interface defining all movie/show streaming operations
- Parallel to anime system but adapted for TMDB/IMDB metadata
- Methods for movies (direct) and TV shows (hierarchical)

## ✅ Completed: Phase 3 - Service Layer

Created `lib/services/extension/movieshow_stream_manager.dart`:
- Complete caching system with appropriate TTLs
- Search functionality for movies and TV shows
- Movie source retrieval
- Season/episode navigation
- Episode source retrieval
- Provider settings management
- Cache management (clear by provider or media)

### Cache Strategy Implemented:
| Data Type | Cache Duration | Cache Key Format |
|-----------|----------------|------------------|
| Search Results | 5 minutes | `search_{provider}_{query}_{mediaType}` |
| Seasons List | 24 hours | `seasons_{provider}_{showId}` |
| Season Episodes | 24 hours | `episodes_{provider}_{showId}_S{season}` |
| Movie Sources | 30 minutes | `movie_{provider}_{movieId}_{server}` |
| Episode Sources | 30 minutes | `episode_{provider}_{showId}_S{season}E{episode}_{server}` |

## ✅ Completed: Phase 4 - Repository Layer

Created `lib/repositories/movieshow_stream_repository.dart`:
- Automatic matching with fuzzy search
- Manual mapping storage (user overrides)
- Complete episode list retrieval
- Intelligent scoring algorithm for best match

## 🔄 Remaining Work

### Phase 5: Android Native Bridge (CRITICAL)

You need to create/update these Kotlin files in `android/app/src/main/kotlin/`:

1. **IMovieShowStreamProvider.kt** - New interface
```kotlin
interface IMovieShowStreamProvider {
    fun search(options: SearchOptions): List<SearchResult>
    fun getStreamServers(): List<String>
    fun getMovieSource(movieId: String, server: String): MovieStreamSource
    fun getSeasons(showId: String): List<SeasonDetails>
    fun getSeasonEpisodes(showId: String, seasonNumber: Int): List<ShowEpisodeDetails>
    fun getEpisodeSource(episode: ShowEpisodeDetails, server: String): EpisodeStreamSource
    fun getSettings(): MovieShowStreamSettings
}
```

2. **Update ExtensionBridge.kt** - Add new method handlers:
```kotlin
"searchMovieShows" -> searchMovieShows(call, result)
"getMovieSource" -> getMovieSource(call, result)
"getSeasons" -> getSeasons(call, result)
"getSeasonEpisodes" -> getSeasonEpisodes(call, result)
"getEpisodeSource" -> getEpisodeSource(call, result)
"getMovieShowSettings" -> getMovieShowSettings(call, result)
```

3. **Create Kotlin data classes** for new models:
   - `MovieStreamSource.kt`
   - `EpisodeStreamSource.kt`
   - `SeasonDetails.kt`
   - `ShowEpisodeDetails.kt`
   - `MovieShowStreamSettings.kt`

4. **Update SearchOptions.kt** - Add `mediaType` and `seasonNumber` fields

### Phase 6: Database Schema

Create database tables for persistence:

```sql
-- Manual mappings
CREATE TABLE movieshow_stream_mappings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    provider_id TEXT NOT NULL,
    tmdb_id TEXT NOT NULL,
    imdb_id TEXT,
    provider_content_id TEXT NOT NULL,
    media_type TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    UNIQUE(provider_id, tmdb_id)
);

-- Cache metadata (optional - currently using Hive)
CREATE TABLE movieshow_stream_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cache_key TEXT UNIQUE NOT NULL,
    provider_id TEXT NOT NULL,
    data TEXT NOT NULL,
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);
```

### Phase 7: UI Components

Create Flutter widgets for:

1. **Provider Selection Screen**
   - List movie/show streaming providers
   - Filter by capabilities (movies/TV/both)
   - Enable/disable providers

2. **Search & Match Interface**
   - Automatic match results
   - Manual search option
   - Match confidence indicator
   - Manual mapping UI

3. **Season/Episode Selector** (TV Shows)
   - Season dropdown/grid
   - Episode list for selected season
   - Episode metadata display

4. **Server Selection**
   - Available servers list
   - Quality indicators
   - Fallback options

5. **Player Integration**
   - Pass video sources to player
   - Subtitle selection
   - Watch progress tracking

### Phase 8: Extension Development

Create example extension and documentation:

1. **Example Extension Structure**
```
my-movieshow-provider/
├── manifest.json
├── icon.png
└── provider.js
```

2. **manifest.json** with `type: "movieshow_stream_provider"`

3. **JavaScript provider implementation** with all required methods

4. **Developer documentation** explaining:
   - How to create movie/show extensions
   - API reference
   - Testing guide
   - Publishing process

### Phase 9: Integration & Testing

1. **Initialize managers in main.dart**
```dart
final movieShowStreamManager = await MovieShowStreamManager.create();
final movieShowStreamRepository = await MovieShowStreamRepository.create(movieShowStreamManager);
```

2. **Unit tests** for:
   - Model serialization
   - Cache expiration
   - Fuzzy matching algorithm

3. **Integration tests** for:
   - Extension loading
   - Method channel communication
   - Database operations

4. **E2E tests** for:
   - Complete search → play flow
   - Manual mapping flow
   - Error recovery

## Key Architecture Decisions

### Parallel System Design
- Movie/show system runs **parallel** to anime system
- Separate managers, repositories, and models
- Shared components: video player, subtitle handling, caching infrastructure

### Episode Numbering
- **Anime**: Absolute numbering (1, 2, 3, ..., 100)
- **TV Shows**: Season + Episode (S01E01, S01E02, S02E01)

### Metadata Sources
- **Anime**: AniList ID (primary), MAL ID (secondary)
- **Movies/Shows**: TMDB ID (primary), IMDB ID (secondary)

### Content Types
- **Movies**: Direct source retrieval (single step)
- **TV Shows**: Hierarchical (Show → Seasons → Episodes → Sources)

## Next Steps

1. **Implement Android native bridge** (Phase 5) - This is critical for the system to work
2. **Create database schema** (Phase 6) - For persistent manual mappings
3. **Build UI components** (Phase 7) - For user interaction
4. **Create example extension** (Phase 8) - For testing and documentation
5. **Write tests** (Phase 9) - Ensure reliability

## Notes

- All Flutter/Dart code is complete and follows the existing architecture patterns
- The system is designed to coexist with the anime streaming system
- Caching strategy is optimized for different data types
- Fuzzy matching algorithm provides intelligent automatic matching
- Manual mapping system allows user overrides when needed
