import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rapid_photo_mobile/features/gallery/models/gallery_state.dart';
import 'package:rapid_photo_mobile/features/gallery/models/paged_photos_response.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_status.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';
import 'package:rapid_photo_mobile/features/gallery/services/gallery_service.dart';

import 'gallery_notifier_test.mocks.dart';

@GenerateMocks([GalleryService])
void main() {
  late MockGalleryService mockGalleryService;
  late ProviderContainer container;

  setUp(() {
    mockGalleryService = MockGalleryService();
    container = ProviderContainer(
      overrides: [
        galleryServiceProvider.overrideWithValue(mockGalleryService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GalleryNotifier', () {
    final testPhotos = [
      PhotoListItem(
        id: 'photo-1',
        fileName: 'test1.jpg',
        status: PhotoStatus.ready,
        thumbnailUrl: 'https://example.com/thumb1.jpg',
        labels: ['nature'],
        createdAt: DateTime.now(),
      ),
      PhotoListItem(
        id: 'photo-2',
        fileName: 'test2.jpg',
        status: PhotoStatus.ready,
        thumbnailUrl: 'https://example.com/thumb2.jpg',
        labels: ['landscape'],
        createdAt: DateTime.now(),
      ),
    ];

    test('should load initial page on build', () async {
      // Arrange
      when(mockGalleryService.getPhotos(
        page: anyNamed('page'),
        size: anyNamed('size'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: testPhotos,
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 1,
            hasNext: false,
          ));

      // Act
      final state = await container.read(galleryProvider.future);

      // Assert
      expect(state.photos.length, 2);
      expect(state.currentPage, 0);
      expect(state.hasMore, false);
      expect(state.totalPhotos, 2);

      verify(mockGalleryService.getPhotos(page: 0, size: 20)).called(1);
    });

    test('should refresh gallery', () async {
      // Arrange
      when(mockGalleryService.getPhotos(
        page: anyNamed('page'),
        size: anyNamed('size'),
        sortBy: anyNamed('sortBy'),
        sortDirection: anyNamed('sortDirection'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: testPhotos,
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 1,
            hasNext: false,
          ));

      // Wait for initial load
      await container.read(galleryProvider.future);

      // Act
      await container.read(galleryProvider.notifier).refresh();

      // Assert
      final state = container.read(galleryProvider).value;
      expect(state?.photos.length, 2);
      expect(state?.isRefreshing, false);

      // Verify refresh was called (initial + refresh)
      verify(mockGalleryService.getPhotos(
        page: 0,
        size: 20,
      )).called(2);
    });

    test('should load next page', () async {
      // Arrange - Initial page
      when(mockGalleryService.getPhotos(
        page: 0,
        size: 20,
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: [testPhotos.first],
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 2,
            hasNext: true,
          ));

      // Arrange - Next page
      when(mockGalleryService.getPhotos(
        page: 1,
        size: 20,
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: [testPhotos.last],
            page: 1,
            size: 20,
            totalElements: 2,
            totalPages: 2,
            hasNext: false,
          ));

      // Wait for initial load
      await container.read(galleryProvider.future);

      // Act
      await container.read(galleryProvider.notifier).loadNextPage();

      // Assert
      final state = container.read(galleryProvider).value;
      expect(state?.photos.length, 2); // Both pages loaded
      expect(state?.currentPage, 1);
      expect(state?.hasMore, false);
    });

    test('should search by tags', () async {
      // Arrange
      when(mockGalleryService.searchPhotosByTag(
        tags: anyNamed('tags'),
        page: anyNamed('page'),
        size: anyNamed('size'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: [testPhotos.first],
            page: 0,
            size: 20,
            totalElements: 1,
            totalPages: 1,
            hasNext: false,
          ));

      // Initial load
      when(mockGalleryService.getPhotos(
        page: anyNamed('page'),
        size: anyNamed('size'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: testPhotos,
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 1,
            hasNext: false,
          ));

      await container.read(galleryProvider.future);

      // Act
      await container.read(galleryProvider.notifier).searchByTags(['nature']);

      // Assert
      final state = container.read(galleryProvider).value;
      expect(state?.photos.length, 1);
      expect(state?.filterTags, ['nature']);

      verify(mockGalleryService.searchPhotosByTag(
        tags: ['nature'],
        page: 0,
        size: 20,
      )).called(1);
    });

    test('should delete photo and remove from list', () async {
      // Arrange
      when(mockGalleryService.getPhotos(
        page: anyNamed('page'),
        size: anyNamed('size'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: testPhotos,
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 1,
            hasNext: false,
          ));

      when(mockGalleryService.deletePhoto(any)).thenAnswer((_) async {});

      await container.read(galleryProvider.future);

      // Act
      await container.read(galleryProvider.notifier).deletePhoto('photo-1');

      // Assert
      final state = container.read(galleryProvider).value;
      expect(state?.photos.length, 1);
      expect(state?.photos.first.id, 'photo-2');
      expect(state?.totalPhotos, 1);

      verify(mockGalleryService.deletePhoto('photo-1')).called(1);
    });

    test('should update sort options', () async {
      // Arrange
      when(mockGalleryService.getPhotos(
        page: anyNamed('page'),
        size: anyNamed('size'),
        sortBy: anyNamed('sortBy'),
        sortDirection: anyNamed('sortDirection'),
      )).thenAnswer((_) async => PagedPhotosResponse(
            content: testPhotos.reversed.toList(),
            page: 0,
            size: 20,
            totalElements: 2,
            totalPages: 1,
            hasNext: false,
          ));

      await container.read(galleryProvider.future);

      // Act
      await container.read(galleryProvider.notifier).updateSort('createdAt', 'asc');

      // Assert
      final state = container.read(galleryProvider).value;
      expect(state?.sortBy, 'createdAt');
      expect(state?.sortDirection, 'asc');

      verify(mockGalleryService.getPhotos(
        page: 0,
        size: 20,
        sortBy: 'createdAt',
        sortDirection: 'asc',
      )).called(1);
    });
  });
}
