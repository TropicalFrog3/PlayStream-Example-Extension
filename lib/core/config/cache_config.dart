import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class TraktImageCacheManager {
  static const key = 'traktImageCache';
  
  static CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30), // Cache images for 30 days
      maxNrOfCacheObjects: 5000, // Maximum number of cached images
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );
}
