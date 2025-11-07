import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rapid_photo_mobile/features/gallery/services/gallery_service.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

/// Service for downloading and sharing photos
class DownloadService {
  final GalleryService _galleryService;
  final AmplifyAuthService _authService;
  final Dio _dio;
  final Logger _logger = Logger();

  DownloadService({
    required GalleryService galleryService,
    required AmplifyAuthService authService,
    required Dio dio,
  })  : _galleryService = galleryService,
        _authService = authService,
        _dio = dio;

  /// Download a photo to device storage
  Future<String> downloadPhoto(
    String photoId,
    String fileName, {
    String? versionType,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Get signed download URL from backend
      final downloadUrl = await _galleryService.getDownloadUrl(
        photoId,
        versionType: versionType,
      );

      // Get directory for downloads
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';

      // Download file
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      _logger.i('Downloaded photo to: $filePath');
      return filePath;
    } catch (e) {
      _logger.e('Failed to download photo: $e');
      rethrow;
    }
  }

  /// Share a photo using platform share dialog
  Future<void> sharePhoto(
    String photoId,
    String fileName, {
    String? versionType,
  }) async {
    try {
      // Download photo first
      final filePath = await downloadPhoto(
        photoId,
        fileName,
        versionType: versionType,
      );

      // Share using platform share
      // Note: This requires the share_plus package
      // For now, we'll just log that the file is ready to share
      _logger.i('Photo ready to share at: $filePath');

      // TODO: Implement actual sharing when share_plus is added
      // await Share.shareXFiles([XFile(filePath)], text: 'Check out this photo!');
    } catch (e) {
      _logger.e('Failed to share photo: $e');
      rethrow;
    }
  }

  /// Download multiple photos
  Future<List<String>> downloadMultiplePhotos(
    List<String> photoIds,
    List<String> fileNames, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final downloadedPaths = <String>[];

    for (var i = 0; i < photoIds.length; i++) {
      try {
        final path = await downloadPhoto(photoIds[i], fileNames[i]);
        downloadedPaths.add(path);

        if (onProgress != null) {
          onProgress(i + 1, photoIds.length);
        }
      } catch (e) {
        _logger.e('Failed to download photo ${photoIds[i]}: $e');
        // Continue with next photo
      }
    }

    return downloadedPaths;
  }

  /// Get the appropriate directory for downloads
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // On Android, use the Downloads directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final downloadDir = Directory('${directory.path}/RapidPhoto');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      }
    }

    // Fallback to application documents directory
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// Check if a file exists in downloads
  Future<bool> isDownloaded(String fileName) async {
    try {
      final directory = await _getDownloadDirectory();
      final file = File('${directory.path}/$fileName');
      return file.exists();
    } catch (e) {
      _logger.e('Failed to check if file exists: $e');
      return false;
    }
  }

  /// Get local path for a downloaded file
  Future<String?> getLocalPath(String fileName) async {
    try {
      final directory = await _getDownloadDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get local path: $e');
      return null;
    }
  }

  /// Delete a downloaded file
  Future<void> deleteLocalFile(String fileName) async {
    try {
      final directory = await _getDownloadDirectory();
      final file = File('${directory.path}/$fileName');

      if (await file.exists()) {
        await file.delete();
        _logger.i('Deleted local file: $fileName');
      }
    } catch (e) {
      _logger.e('Failed to delete local file: $e');
      rethrow;
    }
  }
}

/// Provider for DownloadService
final downloadServiceProvider = Provider<DownloadService>((ref) {
  final galleryService = ref.watch(galleryServiceProvider);
  final authService = ref.watch(amplifyAuthServiceProvider);
  final dio = ref.watch(dioProvider);

  return DownloadService(
    galleryService: galleryService,
    authService: authService,
    dio: dio,
  );
});
