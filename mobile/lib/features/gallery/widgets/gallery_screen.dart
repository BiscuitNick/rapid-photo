import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_list_item.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/photo_detail_screen.dart';
import 'package:rapid_photo_mobile/features/gallery/widgets/search_bar_widget.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
            tooltip: 'Sort options',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SearchBarWidget(),
          ),

          // Gallery grid
          Expanded(
            child: galleryAsync.when(
              data: (state) => _buildGalleryContent(state),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent(state) {
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
                    onTap: () => _navigateToDetail(context, photo.id),
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

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photo.thumbnailUrl,
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
            ),
          ),

          // Status overlay
          if (photo.status.name != 'ready')
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
        ],
      ),
    );
  }

  Color _getStatusColor(status) {
    switch (status.name) {
      case 'ready':
        return Colors.green;
      case 'processing':
      case 'pendingProcessing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(status) {
    switch (status.name) {
      case 'ready':
        return 'Ready';
      case 'processing':
        return 'Processing';
      case 'pendingProcessing':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }
}
