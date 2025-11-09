import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/config/api_config.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

/// Response from generate presigned URL endpoint
class PresignedUrlResponse {
  final String uploadId;  // Changed from uploadJobId to uploadId
  final String presignedUrl;
  final String s3Key;
  final DateTime expiresAt;

  PresignedUrlResponse({
    required this.uploadId,
    required this.presignedUrl,
    required this.s3Key,
    required this.expiresAt,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      uploadId: json['uploadId'].toString(),  // Convert UUID to String
      presignedUrl: json['presignedUrl'] as String,
      s3Key: json['s3Key'] as String,
      expiresAt: _parseDateTime(json['expiresAt']),
    );
  }

  // Backward compatibility getter
  String get uploadJobId => uploadId;

  /// Parse DateTime from either Unix timestamp or ISO string
  static DateTime _parseDateTime(dynamic value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Invalid date format: $value');
  }
}

/// Service for handling upload operations with the backend
class UploadService {
  final Dio _dio;
  final AmplifyAuthService _authService;
  final Logger _logger = Logger();

  UploadService({
    required Dio dio,
    required AmplifyAuthService authService,
  })  : _dio = dio,
        _authService = authService {
    _dio.options.baseUrl = ApiConfig.apiBaseUrl;
    _dio.interceptors.add(_AuthInterceptor(authService));
  }

  /// Generate presigned URL for upload
  Future<PresignedUrlResponse> generatePresignedUrl({
    required String fileName,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      _logger.d('Generating presigned URL for $fileName');

      final response = await _dio.post(
        '/uploads/initiate',
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'mimeType': mimeType,
        },
      );

      return PresignedUrlResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.e('Failed to generate presigned URL: ${e.message}');
      rethrow;
    }
  }

  /// Upload file to S3 using presigned URL
  Future<String> uploadToS3({
    required String presignedUrl,
    required File file,
    required String mimeType,
    void Function(double)? onProgress,
  }) async {
    try {
      _logger.d('Uploading file to S3: ${file.path}');

      final response = await _dio.put(
        presignedUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': await file.length(),
          },
          followRedirects: false,
          validateStatus: (status) => status! < 400,
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      // Extract ETag from response headers
      final etag = response.headers.value('etag');
      if (etag == null) {
        throw Exception('ETag not found in S3 response');
      }

      // Remove quotes from ETag if present
      return etag.replaceAll('"', '');
    } on DioException catch (e) {
      _logger.e('Failed to upload to S3: ${e.message}');
      rethrow;
    }
  }

  /// Confirm upload completion
  Future<void> confirmUpload({
    required String uploadId,
    required String etag,
  }) async {
    try {
      _logger.d('Confirming upload for job $uploadId');

      await _dio.post(
        '/uploads/$uploadId/confirm',
        data: {
          'etag': etag,
        },
      );

      _logger.i('Upload confirmed successfully');
    } on DioException catch (e) {
      _logger.e('Failed to confirm upload: ${e.message}');
      rethrow;
    }
  }

  /// Get batch upload status
  Future<List<Map<String, dynamic>>> getBatchStatus() async {
    try {
      final response = await _dio.get('/uploads/batch/status');
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      _logger.e('Failed to get batch status: ${e.message}');
      rethrow;
    }
  }
}

/// Dio interceptor for adding authentication token
class _AuthInterceptor extends Interceptor {
  final AmplifyAuthService _authService;

  _AuthInterceptor(this._authService);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for S3 presigned URLs
    if (options.path.startsWith('http')) {
      return handler.next(options);
    }

    // Add JWT token to headers
    final token = await _authService.getJwtToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }
}

/// Provider for Dio instance
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
});

/// Provider for UploadService
final uploadServiceProvider = Provider<UploadService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(amplifyAuthServiceProvider);
  return UploadService(dio: dio, authService: authService);
});
