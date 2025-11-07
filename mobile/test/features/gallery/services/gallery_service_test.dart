import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rapid_photo_mobile/features/gallery/models/paged_photos_response.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_response.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_status.dart';
import 'package:rapid_photo_mobile/features/gallery/services/gallery_service.dart';
import 'package:rapid_photo_mobile/shared/auth/amplify_auth_service.dart';

import 'gallery_service_test.mocks.dart';

@GenerateMocks([Dio, AmplifyAuthService])
void main() {
  late GalleryService galleryService;
  late MockDio mockDio;
  late MockAmplifyAuthService mockAuthService;

  setUp(() {
    mockDio = MockDio();
    mockAuthService = MockAmplifyAuthService();
    galleryService = GalleryService(
      dio: mockDio,
      authService: mockAuthService,
    );
  });

  group('GalleryService', () {
    const testToken = 'test-jwt-token';
    const testPhotoId = 'test-photo-id';

    setUp(() {
      when(mockAuthService.getJwtToken()).thenAnswer((_) async => testToken);
    });

    group('getPhotos', () {
      test('should fetch paginated photos successfully', () async {
        // Arrange
        final mockResponse = {
          'content': [
            {
              'id': 'photo-1',
              'fileName': 'test1.jpg',
              'status': 'READY',
              'thumbnailUrl': 'https://example.com/thumb1.jpg',
              'labels': [],
              'createdAt': DateTime.now().toIso8601String(),
            }
          ],
          'page': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrevious': false,
        };

        when(mockDio.get<Map<String, dynamic>>(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: mockResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await galleryService.getPhotos();

        // Assert
        expect(result, isA<PagedPhotosResponse>());
        expect(result.content.length, 1);
        expect(result.page, 0);
        expect(result.totalElements, 1);

        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos',
          queryParameters: {
            'page': 0,
            'size': 20,
          },
          options: anyNamed('options'),
        )).called(1);
      });

      test('should include sort parameters when provided', () async {
        // Arrange
        when(mockDio.get<Map<String, dynamic>>(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: {
                'content': [],
                'page': 0,
                'size': 20,
                'totalElements': 0,
                'totalPages': 0,
                'hasNext': false,
                'hasPrevious': false,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        await galleryService.getPhotos(
          sortBy: 'createdAt',
          sortDirection: 'desc',
        );

        // Assert
        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos',
          queryParameters: {
            'page': 0,
            'size': 20,
            'sortBy': 'createdAt',
            'sortDirection': 'desc',
          },
          options: anyNamed('options'),
        )).called(1);
      });

      test('should throw exception when not authenticated', () async {
        // Arrange
        when(mockAuthService.getJwtToken()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => galleryService.getPhotos(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('searchPhotosByTag', () {
      test('should search photos by tags successfully', () async {
        // Arrange
        final mockResponse = {
          'content': [
            {
              'id': 'photo-1',
              'fileName': 'test1.jpg',
              'status': 'READY',
              'thumbnailUrl': 'https://example.com/thumb1.jpg',
              'labels': ['nature', 'landscape'],
              'createdAt': DateTime.now().toIso8601String(),
            }
          ],
          'page': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
          'hasNext': false,
          'hasPrevious': false,
        };

        when(mockDio.get<Map<String, dynamic>>(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: mockResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await galleryService.searchPhotosByTag(
          tags: ['nature', 'landscape'],
        );

        // Assert
        expect(result, isA<PagedPhotosResponse>());
        expect(result.content.length, 1);

        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos/search',
          queryParameters: {
            'tags': 'nature,landscape',
            'page': 0,
            'size': 20,
          },
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('getPhoto', () {
      test('should fetch single photo successfully', () async {
        // Arrange
        final mockResponse = {
          'id': testPhotoId,
          'fileName': 'test.jpg',
          'status': 'READY',
          'thumbnailUrl': 'https://example.com/thumb.jpg',
          'versions': [],
          'labels': [],
          'createdAt': DateTime.now().toIso8601String(),
        };

        when(mockDio.get<Map<String, dynamic>>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: mockResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await galleryService.getPhoto(testPhotoId);

        // Assert
        expect(result, isA<PhotoResponse>());
        expect(result.id, testPhotoId);

        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos/$testPhotoId',
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('deletePhoto', () {
      test('should delete photo successfully', () async {
        // Arrange
        when(mockDio.delete(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              statusCode: 204,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        await galleryService.deletePhoto(testPhotoId);

        // Assert
        verify(mockDio.delete(
          '/api/v1/photos/$testPhotoId',
          options: anyNamed('options'),
        )).called(1);
      });
    });

    group('getDownloadUrl', () {
      test('should get download URL for original photo', () async {
        // Arrange
        const downloadUrl = 'https://example.com/download/photo.jpg';
        when(mockDio.get<Map<String, dynamic>>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: {'url': downloadUrl},
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await galleryService.getDownloadUrl(testPhotoId);

        // Assert
        expect(result, downloadUrl);

        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos/$testPhotoId/download',
          options: anyNamed('options'),
        )).called(1);
      });

      test('should get download URL for specific version', () async {
        // Arrange
        const versionType = 'WEBP_1280';
        const downloadUrl = 'https://example.com/download/photo_webp.jpg';

        when(mockDio.get<Map<String, dynamic>>(
          any,
          options: anyNamed('options'),
        )).thenAnswer((_) async => Response(
              data: {'url': downloadUrl},
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await galleryService.getDownloadUrl(
          testPhotoId,
          versionType: versionType,
        );

        // Assert
        expect(result, downloadUrl);

        verify(mockDio.get<Map<String, dynamic>>(
          '/api/v1/photos/$testPhotoId/download/$versionType',
          options: anyNamed('options'),
        )).called(1);
      });
    });
  });
}
