import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/features/gallery/models/paged_photos_response.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_response.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

/// Service for gallery API operations
class GalleryService {
  final Dio _dio;
  final AmplifyAuthService _authService;
  final Logger _logger = Logger();

  GalleryService({
    required Dio dio,
    required AmplifyAuthService authService,
  })  : _dio = dio,
        _authService = authService;

  /// Get paginated photos for the current user
  Future<PagedPhotosResponse> getPhotos({
    int page = 0,
    int size = 20,
    String? sortBy,
    String? sortDirection,
  }) async {
    try {
      final token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/photos',
        queryParameters: {
          'page': page,
          'size': size,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return PagedPhotosResponse.fromJson(response.data!);
    } catch (e) {
      _logger.e('Failed to get photos: $e');
      rethrow;
    }
  }

  /// Search photos by tags
  Future<PagedPhotosResponse> searchPhotosByTag({
    required List<String> tags,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/photos/search',
        queryParameters: {
          'tags': tags.join(','),
          'page': page,
          'size': size,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return PagedPhotosResponse.fromJson(response.data!);
    } catch (e) {
      _logger.e('Failed to search photos by tag: $e');
      rethrow;
    }
  }

  /// Get a single photo by ID
  Future<PhotoResponse> getPhoto(String photoId) async {
    try {
      final token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/photos/$photoId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return PhotoResponse.fromJson(response.data!);
    } catch (e) {
      _logger.e('Failed to get photo $photoId: $e');
      rethrow;
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    try {
      final token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      await _dio.delete(
        '/api/v1/photos/$photoId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      _logger.i('Photo $photoId deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete photo $photoId: $e');
      rethrow;
    }
  }

  /// Get download URL for a photo (original or specific version)
  Future<String> getDownloadUrl(
    String photoId, {
    String? versionType,
  }) async {
    try {
      final token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final path = versionType != null
          ? '/api/v1/photos/$photoId/download/$versionType'
          : '/api/v1/photos/$photoId/download';

      final response = await _dio.get<Map<String, dynamic>>(
        path,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data!['url'] as String;
    } catch (e) {
      _logger.e('Failed to get download URL for photo $photoId: $e');
      rethrow;
    }
  }
}

/// Provider for Dio instance with base configuration
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // TODO: Load from environment configuration
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // Add interceptors for logging, error handling, etc.
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => Logger().d(obj),
    ),
  );

  return dio;
});

/// Provider for GalleryService
final galleryServiceProvider = Provider<GalleryService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(amplifyAuthServiceProvider);

  return GalleryService(
    dio: dio,
    authService: authService,
  );
});
