import 'package:logger/logger.dart';
import '../extension/extension_manager.dart';
import '../../models/extension/stream_server.dart';
import '../../models/extension/search_options.dart';
import '../../models/extension/media.dart';

class StreamSource {
  final String url;
  final String quality;
  final String type; // mp4, m3u8, dash
  final Map<String, String>? headers;
  
  StreamSource({
    required this.url,
    required this.quality,
    required this.type,
    this.headers,
  });
  
  /// Create StreamSource from extension StreamServer
  factory StreamSource.fromStreamServer(StreamServer server) {
    return StreamSource(
      url: server.url,
      quality: server.quality,
      type: server.type,
      headers: server.headers,
    );
  }
}

class StreamScraper {
  final ExtensionManager? _extensionManager;
  final Logger _logger = Logger();
  
  // Streaming sources (fallback)
  static const List<String> frenchSources = [
    'https://www.hdss.art',
    'https://www5.hds-streaming.to',
    'https://french-stream.one',
    'https://filmoflix.army',
  ];
  
  StreamScraper({ExtensionManager? extensionManager})
      : _extensionManager = extensionManager;
  
  Future<List<StreamSource>> scrapeMovie({
    required String title,
    int? year,
    String? imdbId,
    String? tmdbId,
  }) async {
    final sources = <StreamSource>[];
    
    // Try extension system first if available
    if (_extensionManager != null) {
      try {
        _logger.i('Searching for movie "$title" using extension system');
        
        // Create SearchOptions with Media metadata
        final searchOptions = SearchOptions(
          media: Media(
            id: 0,
            imdbId: imdbId,
            tmdbId: tmdbId,
            format: 'MOVIE',
            englishTitle: title,
            isAdult: false,
          ),
          query: title,
          year: year,
        );
        
        final searchResults = await _extensionManager.searchAll(searchOptions);
        
        _logger.d('Found ${searchResults.length} results from extensions');
        
        // Get servers from the first matching result
        if (searchResults.isNotEmpty) {
          final firstResult = searchResults.first;
          final enabledExtensions = _extensionManager.getEnabledExtensions();
          
          if (enabledExtensions.isNotEmpty) {
            final extensionId = enabledExtensions.first;
            try {
              final servers = await _extensionManager.findMovieServers(
                extensionId,
                firstResult.id,
              );
              
              // Convert StreamServer to StreamSource
              sources.addAll(
                servers.map((server) => StreamSource.fromStreamServer(server))
              );
              
              _logger.i('Retrieved ${servers.length} servers from extension $extensionId');
            } catch (e) {
              _logger.w('Failed to get servers from extension: $e');
            }
          }
        }
      } catch (e) {
        _logger.e('Error using extension system for movie search: $e');
      }
    }
    
    // Fallback to hardcoded sources if no extension results
    if (sources.isEmpty) {
      _logger.i('Using fallback hardcoded sources');
      for (final sourceUrl in frenchSources) {
        try {
          final scrapedSources = await _scrapeFromSource(
            sourceUrl: sourceUrl,
            title: title,
            year: year,
            imdbId: imdbId,
          );
          sources.addAll(scrapedSources);
        } catch (e) {
          _logger.w('Error scraping from $sourceUrl: $e');
        }
      }
    }
    
    return sources;
  }
  
  Future<List<StreamSource>> _scrapeFromSource({
    required String sourceUrl,
    required String title,
    int? year,
    String? imdbId,
  }) async {
    // This is a placeholder implementation
    // Each streaming site has different HTML structure and requires specific scraping logic
    
    try {
      // This is a placeholder implementation
      // Each streaming site has different HTML structure and requires specific scraping logic
      // TODO: Implement site-specific scraping logic
      // Example:
      // final searchUrl = '$sourceUrl/search?q=${Uri.encodeComponent(title)}';
      // final response = await _dio.get(searchUrl);
      // Parse HTML and extract video sources
      
      return [];
    } catch (e) {
      _logger.w('Scraping error: $e');
      return [];
    }
  }
  
  Future<List<StreamSource>> scrapeShow({
    required String title,
    required int season,
    required int episode,
    String? imdbId,
    String? tmdbId,
  }) async {
    final sources = <StreamSource>[];
    
    // Try extension system first if available
    if (_extensionManager != null) {
      try {
        _logger.i('Searching for show "$title" S${season}E$episode using extension system');
        
        // Create SearchOptions with Media metadata
        final searchOptions = SearchOptions(
          media: Media(
            id: 0,
            imdbId: imdbId,
            tmdbId: tmdbId,
            format: 'TV',
            englishTitle: title,
            isAdult: false,
          ),
          query: title,
        );
        
        final searchResults = await _extensionManager.searchAll(searchOptions);
        
        _logger.d('Found ${searchResults.length} results from extensions');
        
        // Get servers from the first matching result
        if (searchResults.isNotEmpty) {
          final firstResult = searchResults.first;
          final enabledExtensions = _extensionManager.getEnabledExtensions();
          
          if (enabledExtensions.isNotEmpty) {
            final extensionId = enabledExtensions.first;
            try {
              final servers = await _extensionManager.findEpisodeServers(
                extensionId,
                firstResult.id,
                season,
                episode,
              );
              
              // Convert StreamServer to StreamSource
              sources.addAll(
                servers.map((server) => StreamSource.fromStreamServer(server))
              );
              
              _logger.i('Retrieved ${servers.length} servers from extension $extensionId');
            } catch (e) {
              _logger.w('Failed to get servers from extension: $e');
            }
          }
        }
      } catch (e) {
        _logger.e('Error using extension system for show search: $e');
      }
    }
    
    // Fallback to hardcoded sources if no extension results
    if (sources.isEmpty) {
      _logger.i('Using fallback hardcoded sources');
      for (final sourceUrl in frenchSources) {
        try {
          final scrapedSources = await _scrapeShowFromSource(
            sourceUrl: sourceUrl,
            title: title,
            season: season,
            episode: episode,
            imdbId: imdbId,
          );
          sources.addAll(scrapedSources);
        } catch (e) {
          _logger.w('Error scraping from $sourceUrl: $e');
        }
      }
    }
    
    return sources;
  }
  
  Future<List<StreamSource>> _scrapeShowFromSource({
    required String sourceUrl,
    required String title,
    required int season,
    required int episode,
    String? imdbId,
  }) async {
    // Placeholder for show scraping
    return [];
  }
}
