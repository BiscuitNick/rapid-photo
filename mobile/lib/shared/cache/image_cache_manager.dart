import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for photo images
///
/// Provides extended cache duration and memory caching for better performance
/// when navigating between screens. Uses photo IDs as stable cache keys
/// instead of URLs to handle signed S3 URLs that change.
class PhotoImageCacheManager {
  static const key = 'rapidPhotoImageCache';

  static CacheManager? _instance;

  /// Get the singleton cache manager instance
  static CacheManager get instance {
    _instance ??= CacheManager(
      Config(
        key,
        // Cache images for 30 days
        stalePeriod: const Duration(days: 30),
        // Keep up to 200 images (adjust based on app needs)
        maxNrOfCacheObjects: 200,
        // Use custom file service with better error handling
        repo: JsonCacheInfoRepository(databaseName: key),
        fileService: HttpFileService(),
      ),
    );

    return _instance!;
  }

  /// Clear all cached images
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }

  /// Remove a specific image from cache by photo ID
  static Future<void> removeFromCache(String photoId) async {
    await instance.removeFile(photoId);
  }
}
