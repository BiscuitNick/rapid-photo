import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/features/gallery/models/gallery_state.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/services/gallery_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_notifier.g.dart';

/// Notifier for managing gallery state
@riverpod
class GalleryNotifier extends _$GalleryNotifier {
  final Logger _logger = Logger();
  GalleryService get _galleryService => ref.read(galleryServiceProvider);

  @override
  Future<GalleryState> build() async {
    // Initialize with first page
    return _loadInitialPage();
  }

  /// Load the initial page of photos
  Future<GalleryState> _loadInitialPage() async {
    try {
      final response = await _galleryService.getPhotos(
        page: 0,
        size: 20,
      );

      return GalleryState(
        photos: response.content,
        currentPage: response.page,
        hasMore: response.hasNext,
        totalPhotos: response.totalElements,
        isLoading: false,
      );
    } catch (e) {
      _logger.e('Failed to load initial page: $e');
      return GalleryState(error: e.toString());
    }
  }

  /// Refresh the gallery (pull-to-refresh)
  Future<void> refresh() async {
    state = AsyncData(state.value?.copyWith(isRefreshing: true) ?? const GalleryState(isRefreshing: true));

    try {
      final currentState = state.value ?? const GalleryState();
      final response = await _galleryService.getPhotos(
        page: 0,
        size: 20,
        sortBy: currentState.sortBy,
        sortDirection: currentState.sortDirection,
      );

      state = AsyncData(
        currentState.copyWith(
          photos: response.content,
          currentPage: response.page,
          hasMore: response.hasNext,
          totalPhotos: response.totalElements,
          isRefreshing: false,
          error: null,
        ),
      );
    } catch (e) {
      _logger.e('Failed to refresh: $e');
      state = AsyncData(
        (state.value ?? const GalleryState()).copyWith(
          isRefreshing: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Load the next page of photos
  Future<void> loadNextPage() async {
    final currentState = state.value;
    if (currentState == null || !currentState.canLoadMore) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoading: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final response = await _galleryService.getPhotos(
        page: nextPage,
        size: 20,
        sortBy: currentState.sortBy,
        sortDirection: currentState.sortDirection,
      );

      // Append new photos to existing list
      final updatedPhotos = [...currentState.photos, ...response.content];

      state = AsyncData(
        currentState.copyWith(
          photos: updatedPhotos,
          currentPage: response.page,
          hasMore: response.hasNext,
          totalPhotos: response.totalElements,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      _logger.e('Failed to load next page: $e');
      state = AsyncData(
        currentState.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Search photos by tags
  Future<void> searchByTags(List<String> tags) async {
    if (tags.isEmpty) {
      // If no tags, reload the normal gallery
      await refresh();
      return;
    }

    state = AsyncData((state.value ?? const GalleryState()).copyWith(
      isLoading: true,
      filterTags: tags,
    ));

    try {
      final response = await _galleryService.searchPhotosByTag(
        tags: tags,
        page: 0,
        size: 20,
      );

      state = AsyncData(
        GalleryState(
          photos: response.content,
          currentPage: response.page,
          hasMore: response.hasNext,
          totalPhotos: response.totalElements,
          filterTags: tags,
          isLoading: false,
        ),
      );
    } catch (e) {
      _logger.e('Failed to search by tags: $e');
      state = AsyncData(
        (state.value ?? const GalleryState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Clear tag filters
  Future<void> clearFilters() async {
    await refresh();
  }

  /// Update sort options
  Future<void> updateSort(String sortBy, String sortDirection) async {
    state = AsyncData((state.value ?? const GalleryState()).copyWith(
      isLoading: true,
      sortBy: sortBy,
      sortDirection: sortDirection,
    ));

    try {
      final response = await _galleryService.getPhotos(
        page: 0,
        size: 20,
        sortBy: sortBy,
        sortDirection: sortDirection,
      );

      state = AsyncData(
        GalleryState(
          photos: response.content,
          currentPage: response.page,
          hasMore: response.hasNext,
          totalPhotos: response.totalElements,
          sortBy: sortBy,
          sortDirection: sortDirection,
          isLoading: false,
        ),
      );
    } catch (e) {
      _logger.e('Failed to update sort: $e');
      state = AsyncData(
        (state.value ?? const GalleryState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    try {
      await _galleryService.deletePhoto(photoId);

      // Remove from local state
      final currentState = state.value;
      if (currentState != null) {
        final updatedPhotos = currentState.photos
            .where((photo) => photo.id != photoId)
            .toList();

        state = AsyncData(
          currentState.copyWith(
            photos: updatedPhotos,
            totalPhotos: currentState.totalPhotos - 1,
          ),
        );
      }

      _logger.i('Photo $photoId deleted successfully');
    } catch (e) {
      _logger.e('Failed to delete photo: $e');
      state = AsyncData(
        (state.value ?? const GalleryState()).copyWith(
          error: e.toString(),
        ),
      );
      rethrow;
    }
  }
}
