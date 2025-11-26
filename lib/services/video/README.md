# Video Player Extension Integration

This document describes the integration between the video player and the extension system.

## Overview

The video player has been updated to work seamlessly with the extension system, allowing users to:
- Search for content across multiple extensions
- Select from available streaming servers
- Switch between servers during playback
- Automatic fallback to alternative servers on failure

## Components

### 1. StreamScraper (`stream_scraper.dart`)

Updated to use ExtensionManager for content discovery:
- Searches across all enabled extensions first
- Falls back to hardcoded sources if no extension results
- Converts extension `StreamServer` objects to legacy `StreamSource` format

**Usage:**
```dart
final scraper = StreamScraper(extensionManager: extensionManager);
final sources = await scraper.scrapeMovie(title: 'Movie Title', year: 2024);
```

### 2. CustomVideoPlayerController (`video_player_controller.dart`)

Enhanced to support StreamServer objects:
- Accepts `StreamServer` with URL, headers, and metadata
- Supports fallback servers for automatic retry
- Handles server switching during playback
- Maintains playback position when switching servers

**New Methods:**
- `initializeWithServer(StreamServer, {fallbackServers})` - Initialize with extension server
- `switchServer(StreamServer)` - Switch to a different server
- `retry()` - Retry with current server
- `_tryFallbackServer()` - Automatically try next fallback server

**Usage:**
```dart
final controller = CustomVideoPlayerController();
await controller.initializeWithServer(
  server,
  fallbackServers: [server2, server3],
);
```

### 3. PlayerScreen (`player_screen.dart`)

Updated to support both legacy URL and new StreamServer modes:
- Accepts either `videoUrl` (legacy) or `server` (new)
- Displays server selection button when multiple servers available
- Shows retry and server selection options on error
- Displays current server information

**Usage:**
```dart
// New way with StreamServer
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlayerScreen(
      title: 'Movie Title',
      server: selectedServer,
      availableServers: allServers,
      contentId: 'movie:123',
    ),
  ),
);

// Legacy way with URL (still supported)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PlayerScreen(
      title: 'Movie Title',
      videoUrl: 'https://example.com/video.mp4',
    ),
  ),
);
```

### 4. ServerSelectionDialog (`server_selection_dialog.dart`)

New widget for server selection:
- Groups servers by extension
- Shows server quality, type, and name
- Persists user preferences per content item
- Visual indicators for selected server

**Usage:**
```dart
final selectedServer = await showServerSelectionDialog(
  context: context,
  serversByExtension: {
    'Extension1': [server1, server2],
    'Extension2': [server3, server4],
  },
  contentId: 'movie:123',
);
```

### 5. VideoPlaybackHelper (`video_playback_helper.dart`)

Helper class for easy video playback:
- Simplifies the process of playing movies and episodes
- Handles search, server retrieval, and navigation
- Provides error handling and user feedback

**Usage:**
```dart
final helper = VideoPlaybackHelper(extensionManager);

// Play a movie
await helper.playMovie(
  context: context,
  title: 'Movie Title',
  year: 2024,
);

// Play an episode
await helper.playEpisode(
  context: context,
  title: 'Show Title',
  season: 1,
  episode: 5,
);
```

## Integration Flow

### Movie Playback Flow

1. User selects a movie to watch
2. `VideoPlaybackHelper.playMovie()` is called
3. Extension system searches for the movie across all enabled extensions
4. First matching result is selected
5. `ExtensionManager.findMovieServers()` retrieves available servers
6. `PlayerScreen` is launched with the first server and fallback servers
7. User can switch servers using the server selection button
8. If a server fails, automatic fallback to next server occurs

### Episode Playback Flow

1. User selects an episode to watch
2. `VideoPlaybackHelper.playEpisode()` is called
3. Extension system searches for the show across all enabled extensions
4. First matching result is selected
5. `ExtensionManager.findEpisodeServers()` retrieves servers for the specific episode
6. `PlayerScreen` is launched with the first server and fallback servers
7. User can switch servers using the server selection button
8. If a server fails, automatic fallback to next server occurs

## Error Handling

The integration includes comprehensive error handling:

1. **Network Errors**: Automatically retry with fallback servers
2. **Server Failures**: Display error message with retry and server selection options
3. **No Results**: Show user-friendly error message
4. **Extension Failures**: Continue with other extensions, log errors

## Server Preferences

User server preferences are persisted using Hive:
- Stored per content item (movie or episode)
- Automatically restored on subsequent playback
- Stored in `server_preferences` Hive box

## Backward Compatibility

The integration maintains backward compatibility:
- `PlayerScreen` still accepts `videoUrl` parameter
- `CustomVideoPlayerController.initialize(url)` still works
- Existing code using direct URLs continues to function

## Future Enhancements

Potential improvements:
1. Server quality auto-selection based on network speed
2. Server performance tracking and ranking
3. Subtitle support from extensions
4. Multi-audio track support
5. Download functionality for offline playback
