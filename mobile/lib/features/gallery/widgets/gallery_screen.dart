import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/models/gallery_state.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_status.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/photo_detail_screen.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/search_bar_widget.dart';
import 'package:rapid_photo_mobile/shared/cache/image_cache_manager.dart';

/// Main gallery screen showing photo grid
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      ref.read(galleryProvider.notifier).loadNextPage();
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final galleryAsync = ref.watch(galleryProvider);

    return galleryAsync.when(
      data: (state) => Scaffold(
        appBar: _buildAppBar(context, state),
        body: Column(
          children: [
            // Search bar (hide in selection mode)
            if (!state.isSelectionMode)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SearchBarWidget(),
              ),

            // Gallery grid
            Expanded(
              child: _buildGalleryContent(state),
            ),
          ],
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Gallery')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(galleryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, GalleryState state) {
    if (state.isSelectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => ref.read(galleryProvider.notifier).toggleSelectionMode(),
        ),
        title: Text('${state.selectedPhotoIds.length} selected'),
        actions: [
          if (state.selectedPhotoIds.length < state.photos.length)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => ref.read(galleryProvider.notifier).selectAll(),
              tooltip: 'Select all',
            ),
          if (state.selectedPhotoIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, state.selectedPhotoIds.length),
              tooltip: 'Delete selected',
            ),
        ],
      );
    }

    return AppBar(
      title: const Text('Gallery'),
      actions: [
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: () => ref.read(galleryProvider.notifier).toggleSelectionMode(),
          tooltip: 'Select photos',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortOptions(context),
          tooltip: 'Sort options',
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photos'),
        content: Text('Are you sure you want to delete $count photo${count == 1 ? '' : 's'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(galleryProvider.notifier).deleteSelectedPhotos();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent(GalleryState state) {
    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No photos yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.upload),
              label: const Text('Upload Photos'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(galleryProvider.notifier).refresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Active filter chips
          if (state.filterTags.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ...state.filterTags.map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () {
                          final updatedTags = List<String>.from(state.filterTags)
                            ..remove(tag);
                          if (updatedTags.isEmpty) {
                            ref.read(galleryProvider.notifier).clearFilters();
                          } else {
                            ref.read(galleryProvider.notifier).searchByTags(updatedTags);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Photo count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${state.totalPhotos} photo${state.totalPhotos == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          // Photo grid
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = state.photos[index];
                  return PhotoGridItem(
                    photo: photo,
                    isSelectionMode: state.isSelectionMode,
                    isSelected: state.selectedPhotoIds.contains(photo.id),
                    onTap: () {
                      if (state.isSelectionMode) {
                        ref.read(galleryProvider.notifier).togglePhotoSelection(photo.id);
                      } else {
                        _navigateToDetail(context, photo.id);
                      }
                    },
                    onLongPress: () {
                      if (!state.isSelectionMode) {
                        ref.read(galleryProvider.notifier).toggleSelectionMode();
                        ref.read(galleryProvider.notifier).togglePhotoSelection(photo.id);
                      }
                    },
                  );
                },
                childCount: state.photos.length,
              ),
            ),
          ),

          // Loading indicator for pagination
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String photoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailScreen(photoId: photoId),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Upload Date (Newest)'),
            onTap: () {
              ref.read(galleryProvider.notifier).updateSort('createdAt', 'desc');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Upload Date (Oldest)'),
            onTap: () {
              ref.read(galleryProvider.notifier).updateSort('createdAt', 'asc');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Photo Date (Newest)'),
            onTap: () {
              ref.read(galleryProvider.notifier).updateSort('takenAt', 'desc');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text('Photo Date (Oldest)'),
            onTap: () {
              ref.read(galleryProvider.notifier).updateSort('takenAt', 'asc');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// Grid item widget for a photo
class PhotoGridItem extends StatelessWidget {
  final PhotoListItem photo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image (fallback to original if thumbnail not available)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (photo.thumbnailUrl ?? photo.originalUrl) != null
                ? CachedNetworkImage(
                    imageUrl: photo.thumbnailUrl ?? photo.originalUrl!,
                    cacheKey: '${photo.id}_thumbnail',
                    cacheManager: PhotoImageCacheManager.instance,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Status overlay
          if (photo.status != PhotoStatus.ready)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(photo.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(photo.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Label count badge
          if (photo.labels.isNotEmpty)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.label, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${photo.labels.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Selection overlay and indicator
          if (isSelectionMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
            ),

          // Selection checkmark
          if (isSelectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.blue : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(PhotoStatus status) {
    switch (status) {
      case PhotoStatus.ready:
        return Colors.green;
      case PhotoStatus.processing:
      case PhotoStatus.pendingProcessing:
        return Colors.orange;
      case PhotoStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusLabel(PhotoStatus status) {
    switch (status) {
      case PhotoStatus.ready:
        return 'Ready';
      case PhotoStatus.processing:
        return 'Processing';
      case PhotoStatus.pendingProcessing:
        return 'Pending';
      case PhotoStatus.failed:
        return 'Failed';
    }
  }
}
