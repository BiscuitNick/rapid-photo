import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_photo_mobile/features/gallery/models/gallery_state.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_status.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/gallery_screen.dart';

void main() {
  group('GalleryScreen Widget Tests', () {
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

    Widget createTestWidget(AsyncValue<GalleryState> state) {
      return ProviderScope(
        overrides: [
          galleryProvider.overrideWith((ref) {
            return TestGalleryNotifier(state);
          }),
        ],
        child: const MaterialApp(
          home: GalleryScreen(),
        ),
      );
    }

    testWidgets('should display loading indicator when loading',
        (WidgetTester tester) async {
      // Arrange
      final state = const AsyncValue<GalleryState>.loading();

      // Act
      await tester.pumpWidget(createTestWidget(state));

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when there is an error',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue<GalleryState>.error(
        'Failed to load photos',
        StackTrace.current,
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));

      // Assert
      expect(find.text('Error: Failed to load photos'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display empty state when no photos',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue.data(const GalleryState());

      // Act
      await tester.pumpWidget(createTestWidget(state));

      // Assert
      expect(find.text('No photos yet'), findsOneWidget);
      expect(find.text('Upload Photos'), findsOneWidget);
    });

    testWidgets('should display photo grid when photos are loaded',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue.data(
        GalleryState(
          photos: testPhotos,
          totalPhotos: testPhotos.length,
          hasMore: false,
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(PhotoGridItem), findsNWidgets(2));
      expect(find.text('2 photos'), findsOneWidget);
    });

    testWidgets('should display search bar', (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue.data(
        GalleryState(photos: testPhotos),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search by tag...'), findsOneWidget);
    });

    testWidgets('should display active filter chips',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue.data(
        GalleryState(
          photos: testPhotos,
          filterTags: ['nature', 'landscape'],
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('nature'), findsOneWidget);
      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('should show loading indicator when paginating',
        (WidgetTester tester) async {
      // Arrange
      final state = AsyncValue.data(
        GalleryState(
          photos: testPhotos,
          isLoading: true,
          hasMore: true,
        ),
      );

      // Act
      await tester.pumpWidget(createTestWidget(state));
      await tester.pumpAndSettle();

      // Assert
      // Should show both the grid and a loading indicator at the bottom
      expect(find.byType(PhotoGridItem), findsNWidgets(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// Test implementation of GalleryNotifier for widget testing
class TestGalleryNotifier extends AutoDisposeAsyncNotifier<GalleryState> {
  final AsyncValue<GalleryState> _state;

  TestGalleryNotifier(this._state);

  @override
  Future<GalleryState> build() async {
    return _state.when(
      data: (data) => data,
      loading: () => const GalleryState(isLoading: true),
      error: (error, stack) => GalleryState(error: error.toString()),
    );
  }

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadNextPage() async {}

  @override
  Future<void> searchByTags(List<String> tags) async {}

  @override
  Future<void> clearFilters() async {}

  @override
  Future<void> updateSort(String sortBy, String sortDirection) async {}

  @override
  Future<void> deletePhoto(String photoId) async {}
}
