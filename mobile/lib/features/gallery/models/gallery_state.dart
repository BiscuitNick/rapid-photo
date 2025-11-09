import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_list_item.dart';

part 'gallery_state.freezed.dart';
part 'gallery_state.g.dart';

/// State for the gallery screen
@freezed
abstract class GalleryState with _$GalleryState {
  const factory GalleryState({
    /// List of photos
    @Default([]) List<PhotoListItem> photos,

    /// Current page number
    @Default(0) int currentPage,

    /// Whether there are more pages to load
    @Default(true) bool hasMore,

    /// Total number of photos
    @Default(0) int totalPhotos,

    /// Active filter tags
    @Default([]) List<String> filterTags,

    /// Sort field (e.g., 'createdAt', 'takenAt')
    String? sortBy,

    /// Sort direction ('asc' or 'desc')
    @Default('desc') String sortDirection,

    /// Whether currently loading
    @Default(false) bool isLoading,

    /// Whether currently refreshing
    @Default(false) bool isRefreshing,

    /// Error message if any
    String? error,

    /// Whether in selection mode for deletion
    @Default(false) bool isSelectionMode,

    /// Set of selected photo IDs
    @Default({}) Set<String> selectedPhotoIds,
  }) = _GalleryState;

  factory GalleryState.fromJson(Map<String, dynamic> json) =>
      _$GalleryStateFromJson(json);
}

extension GalleryStateExtensions on GalleryState {
  /// Check if the gallery is empty
  bool get isEmpty => photos.isEmpty && !isLoading && !isRefreshing;

  /// Check if we can load more
  bool get canLoadMore => hasMore && !isLoading;
}
