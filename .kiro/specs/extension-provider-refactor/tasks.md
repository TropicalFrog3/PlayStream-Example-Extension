# Implementation Plan

- [x] 1. Create data model classes in new models package
- [x] 1.1 Create models package structure
  - Create package `com.playstream.extension.models` in `example-extension/src/main/kotlin/com/playstream/extension/models/`
  - This package will contain all shared data models for the extension system
  - _Requirements: All data model requirements_

- [x] 1.2 Create VideoSourceType enum
  - Create file `VideoSourceType.kt` in models package
  - Define enum with two values: `MP4` and `M3U8`
  - Add `@SerializedName` annotations for Gson to serialize as lowercase strings ("mp4", "m3u8")
  - Example: `@SerializedName("mp4") MP4, @SerializedName("m3u8") M3U8`
  - _Requirements: 3.5_

- [x] 1.3 Create VideoSubtitle data class
  - Create file `VideoSubtitle.kt` in models package
  - Define data class with fields:
    - `id: String` - unique identifier for the subtitle track
    - `url: String` - URL to the subtitle file (VTT, SRT, etc.)
    - `language: String` - language code (e.g., "en", "es", "fr")
    - `isDefault: Boolean` - whether this subtitle should be selected by default
  - All fields are required and non-nullable
  - _Requirements: 3.8_

- [x] 1.4 Create VideoSource data class
  - Create file `VideoSource.kt` in models package
  - Define data class with fields:
    - `url: String` - streaming URL (HLS m3u8 or direct MP4)
    - `type: VideoSourceType` - enum value indicating stream type
    - `quality: String` - quality label (e.g., "1080p", "720p", "auto")
    - `subtitles: List<VideoSubtitle>` - list of available subtitles (can be empty)
  - Default subtitles to `emptyList()` in constructor
  - _Requirements: 3.4, 3.5, 3.6, 3.7_

- [x] 1.5 Create EpisodeServer data class
  - Create file `EpisodeServer.kt` in models package
  - Define data class with fields:
    - `server: String` - server name/identifier (e.g., "vidking", "streamtape")
    - `headers: Map<String, String>` - HTTP headers required for playback (e.g., Referer, User-Agent)
    - `videoSources: List<VideoSource>` - list of available video sources (must have at least one)
  - Default headers to `emptyMap()` in constructor
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 1.6 Create SearchResult data class
  - Create file `SearchResult.kt` in models package
  - Define data class with fields:
    - `id: String` - unique identifier for the content (used in findEpisodes)
    - `title: String` - display title of the movie/show
    - `url: String` - URL to the content page on the provider's site
  - All fields are required String types, must be non-empty
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 1.7 Create EpisodeDetails data class
  - Create file `EpisodeDetails.kt` in models package
  - Define data class with fields:
    - `id: String` - unique identifier for the episode (used in findEpisodeServer)
    - `number: Int` - episode number (must be positive, starting from 1)
    - `url: String` - URL to the episode page
    - `title: String? = null` - optional episode title
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [x] 1.8 Create FuzzyDate data class
  - Create file `FuzzyDate.kt` in models package
  - Define data class with fields:
    - `year: Int` - required year value
    - `month: Int? = null` - optional month (1-12)
    - `day: Int? = null` - optional day (1-31)
  - Used for representing partial dates (e.g., release dates where only year is known)
  - _Requirements: 4.9_

- [x] 1.9 Create Media data class
  - Create file `Media.kt` in models package
  - Define data class with fields:
    - `id: Int` - internal identifier (non-negative)
    - `imdbId: String? = null` - IMDB ID (e.g., "tt1234567")
    - `tmdbId: String? = null` - TMDB ID (e.g., "12345")
    - `status: String? = null` - release status (e.g., "Released", "Ongoing")
    - `format: String? = null` - media format (e.g., "MOVIE", "TV")
    - `englishTitle: String? = null` - English title of the content
    - `episodeCount: Int? = null` - total number of episodes (for TV shows)
    - `absoluteSeasonOffset: Int? = null` - offset for absolute episode numbering
    - `synonyms: List<String> = emptyList()` - alternative titles/names
    - `isAdult: Boolean` - whether content is adult-only
    - `startDate: FuzzyDate? = null` - release/air date
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9_

- [x] 1.10 Create SearchOptions data class
  - Create file `SearchOptions.kt` in models package
  - Define data class with fields:
    - `media: Media` - metadata about the content being searched
    - `query: String` - search query string (must be non-empty)
    - `year: Int? = null` - optional year filter for search results
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 1.11 Create Settings data class
  - Create file `Settings.kt` in models package
  - Define data class with fields:
    - `episodeServers: List<String>` - list of available server names that can be passed to findEpisodeServer
  - Example: `Settings(episodeServers = listOf("vidking", "streamtape", "doodstream"))`
  - _Requirements: 6.1_

- [x] 2. Create MediaProvider abstract class
- [x] 2.1 Define MediaProvider abstract class
  - Create file `MediaProvider.kt` in `example-extension/src/main/kotlin/com/playstream/extension/`
  - Define abstract class with the following abstract methods:
    ```kotlin
    abstract class MediaProvider {
        abstract fun search(opts: SearchOptions): List<SearchResult>
        abstract fun findEpisodes(id: String): List<EpisodeDetails>
        abstract fun findEpisodeServer(episode: EpisodeDetails, server: String): EpisodeServer
        abstract fun getSettings(): Settings
    }
    ```
  - Import all model classes from the models package
  - This class serves as the contract that all streaming providers must implement
  - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 3. Update ExampleProvider to implement new interface
- [x] 3.1 Refactor ExampleProvider class declaration
  - Update `ExampleProvider.kt` in `example-extension/src/main/kotlin/com/playstream/extension/example/`
  - Change class to extend `MediaProvider` abstract class instead of implementing `IExtensionProvider`
  - Update imports to include all new model classes from `com.playstream.extension.models`
  - Remove old interface implementation and related imports
  - Keep Gson instance for JSON serialization
  - _Requirements: 10.5_

- [x] 3.2 Implement search method with new signature
  - Override `search(opts: SearchOptions): List<SearchResult>` method
  - Extract search parameters from SearchOptions:
    - Use `opts.media.tmdbId` for TMDB-based lookups
    - Use `opts.media.imdbId` for IMDB-based lookups
    - Use `opts.query` for text-based search
    - Use `opts.year` for year filtering (if provided)
  - Build Vidking URLs using existing helper methods
  - Return `List<SearchResult>` with proper id, title, url fields
  - Return empty list if query is empty and no IDs are provided
  - Log search parameters and results count
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 3.3 Implement findEpisodes method
  - Override `findEpisodes(id: String): List<EpisodeDetails>` method
  - Parse the id parameter to extract TMDB ID and season information
  - Generate episode list with sequential episode numbers starting from 1
  - Each EpisodeDetails should have:
    - `id`: unique episode identifier (e.g., "tv:12345:1:3" for season 1 episode 3)
    - `number`: episode number (1, 2, 3, ...)
    - `url`: Vidking embed URL for the episode
    - `title`: optional episode title (e.g., "Episode 3")
  - Return empty list if no episodes found
  - Throw exception with details if ID is invalid
  - Log episode count and any errors
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 3.4 Implement findEpisodeServer method with new signature
  - Override `findEpisodeServer(episode: EpisodeDetails, server: String): EpisodeServer` method
  - Use `episode.id` to determine content type (movie vs TV)
  - Use `server` parameter to select appropriate streaming server
  - Build EpisodeServer response with:
    - `server`: the server name (e.g., "vidking")
    - `headers`: required HTTP headers (e.g., `mapOf("Referer" to "https://www.vidking.net")`)
    - `videoSources`: list containing at least one VideoSource with:
      - `url`: streaming URL (Vidking embed URL)
      - `type`: VideoSourceType.M3U8 for HLS streams
      - `quality`: quality string (e.g., "auto", "1080p")
      - `subtitles`: empty list or available subtitles
  - Throw exception if server is not available or episode ID is invalid
  - Log server request and response details
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 3.5 Implement getSettings method
  - Override `getSettings(): Settings` method
  - Return Settings object with:
    - `episodeServers`: list of available server names (e.g., `listOf("vidking")`)
  - This tells the client which servers can be passed to findEpisodeServer
  - Log settings retrieval
  - _Requirements: 6.1, 6.2, 6.3_

- [x] 3.6 Remove deprecated methods and clean up
  - Remove old `search(query, imdbId, tmdbId, mediaType)` method signature
  - Remove old `findEpisodeServer(episodeId)` method signature (single parameter)
  - Remove any unused helper methods or constants
  - Update logging to reflect new method names
  - Ensure all public methods match MediaProvider abstract class
  - _Requirements: 10.5_

- [x] 4. Update Flutter integration layer
- [x] 4.1 Update Dart SearchResult model
  - Update `lib/models/extension/search_result.dart`
  - Ensure fields match Kotlin model: `id`, `title`, `url`
  - Update `fromJson` factory constructor to parse new structure
  - Update `toJson` method for serialization
  - _Requirements: 1.4, 1.5_

- [x] 4.2 Update Dart EpisodeDetails model
  - Create or update `lib/models/extension/episode_details.dart`
  - Define fields: `id` (String), `number` (int), `url` (String), `title` (String?)
  - Implement `fromJson` factory constructor
  - Implement `toJson` method
  - _Requirements: 2.5, 2.6_

- [x] 4.3 Create Dart VideoSubtitle model
  - Create `lib/models/extension/video_subtitle.dart`
  - Define fields: `id` (String), `url` (String), `language` (String), `isDefault` (bool)
  - Implement `fromJson` factory constructor
  - Implement `toJson` method
  - _Requirements: 3.8_

- [x] 4.4 Create Dart VideoSource model
  - Create `lib/models/extension/video_source.dart`
  - Define fields: `url` (String), `type` (String), `quality` (String), `subtitles` (List<VideoSubtitle>)
  - Implement `fromJson` factory constructor with nested VideoSubtitle parsing
  - Implement `toJson` method
  - _Requirements: 3.4, 3.5, 3.6, 3.7_

- [x] 4.5 Update Dart StreamServer/EpisodeServer model
  - Update `lib/models/extension/stream_server.dart` or create `episode_server.dart`
  - Define fields: `server` (String), `headers` (Map<String, String>), `videoSources` (List<VideoSource>)
  - Implement `fromJson` factory constructor with nested VideoSource parsing
  - Implement `toJson` method
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 4.6 Create Dart Media and SearchOptions models
  - Create `lib/models/extension/media.dart` with all Media fields
  - Create `lib/models/extension/search_options.dart` with media, query, year fields
  - Create `lib/models/extension/fuzzy_date.dart` with year, month, day fields
  - Implement JSON serialization for all models
  - _Requirements: 4.1-4.9, 5.1-5.4_

- [x] 4.7 Update ExtensionManager search method
  - Update `lib/services/extension/extension_manager.dart`
  - Modify `searchAll` method to accept SearchOptions or equivalent parameters
  - Build SearchOptions JSON to send to Kotlin via method channel
  - Parse response as List<SearchResult>
  - _Requirements: 7.1_

- [x] 4.8 Update ExtensionManager findEpisodes method
  - Update method to accept string ID parameter
  - Parse response as List<EpisodeDetails>
  - Handle empty list response
  - _Requirements: 8.1_

- [x] 4.9 Update ExtensionManager findEpisodeServer method
  - Update method signature to accept EpisodeDetails and server name
  - Build request JSON with episode details and server parameter
  - Parse response as EpisodeServer with nested VideoSource objects
  - _Requirements: 9.1_

- [x] 5. Checkpoint - Verify integration works
  - Ensure all Kotlin code compiles without errors
  - Ensure all Dart code compiles without errors
  - Verify method channel communication between Flutter and Kotlin works
  - Test basic search flow end-to-end
  - Ask the user if questions arise

