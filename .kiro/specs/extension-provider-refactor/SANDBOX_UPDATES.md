# Extension Sandbox Updates for New Architecture

## Overview

The Extension Sandbox has been updated to work with the new MediaProvider architecture that uses `SearchOptions` instead of simple parameters.

## Changes Made

### 1. Import Updates
Added imports for the new data models:
```dart
import '../../models/extension/search_options.dart';
import '../../models/extension/media.dart';
```

### 2. New UI Field: Server Name
Added a server name text field for the `findEpisodeServer` method:
- Controller: `_serverNameController` (default value: "vidking")
- Only visible when `findEpisodeServer` method is selected
- Allows users to specify which server to query

### 3. Search Method Updates with Trakt Integration

**Old Approach:**
```dart
args['query'] = mediaTitleController.text.trim();
args['imdbId'] = imdbIdController.text.trim();
args['tmdbId'] = tmdbIdController.text.trim();
args['mediaType'] = _selectedMediaType;
```

**New Approach with Trakt Metadata Fetching:**
```dart
// Query is required - use media title, or fallback to TMDB/IMDB ID
String query = mediaTitle;
if (query.isEmpty) {
  if (tmdbId.isNotEmpty) {
    query = 'TMDB:$tmdbId';
  } else if (imdbId.isNotEmpty) {
    query = 'IMDB:$imdbId';
  } else {
    query = 'search'; // Fallback placeholder
  }
}

// Fetch rich metadata from Trakt if TMDB or IMDB ID is provided
Media? media;

if (tmdbId.isNotEmpty || imdbId.isNotEmpty) {
  try {
    final traktClient = ref.read(traktClientProvider);
    final idType = tmdbId.isNotEmpty ? 'tmdb' : 'imdb';
    final idValue = tmdbId.isNotEmpty ? tmdbId : imdbId;
    
    // Search by ID using Trakt API
    final searchResults = await traktClient.search.searchById(idType, idValue);
    
    if (searchResults.isNotEmpty) {
      final result = searchResults.first;
      
      // Extract full metadata (title, IDs, release date, etc.)
      if (result['type'] == 'movie' && result['movie'] != null) {
        final movie = result['movie'];
        final ids = movie['ids'];
        
        media = Media(
          id: ids['trakt'] ?? 0,
          imdbId: ids['imdb'],
          tmdbId: ids['tmdb']?.toString(),
          format: 'MOVIE',
          englishTitle: movie['title'],
          synonyms: [],
          isAdult: false,
          startDate: _parseFuzzyDate(movie['released']),
        );
      }
      // Similar for TV shows...
    }
  } catch (e) {
    // Fallback to basic media object if Trakt fetch fails
  }
}

// Fallback to basic Media object if needed
media ??= Media(
  id: 0,
  imdbId: imdbId.isNotEmpty ? imdbId : null,
  tmdbId: tmdbId.isNotEmpty ? tmdbId : null,
  format: _selectedMediaType?.toUpperCase(),
  englishTitle: mediaTitle.isNotEmpty ? mediaTitle : null,
  synonyms: [],
  isAdult: false,
);

// Create SearchOptions object
final searchOptions = SearchOptions(
  media: media,
  query: query, // Now guaranteed to be non-empty
  year: null,
);

// Convert to JSON for method channel
args['searchOptions'] = searchOptions.toJson();
```

### 4. findEpisodes Method Updates

**Old Approach:**
```dart
args['showId'] = mediaTitleController.text.trim();
```

**New Approach:**
```dart
args['id'] = mediaTitleController.text.trim();
```

### 5. findEpisodeServer Method Updates

**Old Approach:**
```dart
args['episodeId'] = mediaTitleController.text.trim();
```

**New Approach:**
```dart
// Parse episode ID and create EpisodeDetails object
final episodeDetails = {
  'id': episodeId,
  'number': parts.length >= 4 ? int.tryParse(parts[3]) ?? 1 : 1,
  'url': '',
  'title': null,
};

args['episode'] = episodeDetails;
args['server'] = serverName; // From _serverNameController
```

## Usage Examples

### Testing Search

**Option 1: Search with Title**
1. Select extension: "Example Extension"
2. Select method: "search"
3. Enter media title: "Fight Club"
4. Enter TMDB ID (optional): "550"
5. Enter IMDB ID (optional): "tt0137523"
6. Select media type (optional): "Movie"
7. Click "Execute"

**Option 2: Search with IDs Only**
1. Select extension: "Example Extension"
2. Select method: "search"
3. Leave media title empty
4. Enter TMDB ID: "550"
5. Enter IMDB ID (optional): "tt0137523"
6. Select media type (optional): "Movie"
7. Click "Execute"

**Note:** At least one of the following is required: Media Title, TMDB ID, or IMDB ID. The query field will be auto-populated with the title or ID.

### Testing findEpisodes
1. Select extension: "Example Extension"
2. Select method: "findEpisodes"
3. Enter show ID: "tv:114472" or "tv:114472:1:1"
4. Click "Execute"

### Testing findEpisodeServer
1. Select extension: "Example Extension"
2. Select method: "findEpisodeServer"
3. Enter episode ID: "tv:114472:1:1" or "movie:550"
4. Enter server name: "vidking" (default)
5. Click "Execute"

## Benefits

1. **Type Safety**: Uses strongly-typed data models instead of raw maps
2. **Rich Metadata**: Media object contains comprehensive metadata fetched from Trakt API
   - Trakt ID, IMDB ID, TMDB ID
   - Accurate title from Trakt database
   - Release/air dates
   - Media format (MOVIE/TV)
3. **Automatic Metadata Enrichment**: When TMDB or IMDB ID is provided, the sandbox automatically fetches full metadata from Trakt
4. **Flexibility**: Server name can be customized for testing different providers
5. **Consistency**: Matches the new MediaProvider interface exactly
6. **Fallback Support**: Gracefully handles Trakt API failures by using basic metadata

## Migration Notes

- Old sandbox tests using the previous parameter format will need to be updated
- The method channel communication now expects `SearchOptions` JSON for search
- `findEpisodeServer` now requires both `episode` (EpisodeDetails) and `server` (String) parameters
