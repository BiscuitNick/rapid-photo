import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_response.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_status.dart';
import 'package:rapid_photo_mobile/features/gallery/models/photo_version_type.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/gallery_notifier.dart';
import 'package:rapid_photo_mobile/features/gallery/providers/photo_detail_provider.dart';
import 'package:rapid_photo_mobile/features/gallery/services/download_service.dart';
import 'package:rapid_photo_mobile/shared/cache/image_cache_manager.dart';
import 'package:intl/intl.dart';

/// Photo detail screen showing full metadata and actions
class PhotoDetailScreen extends ConsumerWidget {
  final String photoId;

  const PhotoDetailScreen({
    super.key,
    required this.photoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoAsync = ref.watch(photoDetailProvider(photoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete photo',
          ),
        ],
      ),
      body: photoAsync.when(
        data: (photo) => _buildPhotoDetail(context, ref, photo),
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
                onPressed: () => ref.invalidate(photoDetailProvider(photoId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoDetail(
    BuildContext context,
    WidgetRef ref,
    PhotoResponse photo,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main image
          AspectRatio(
            aspectRatio: photo.width != null && photo.height != null
                ? photo.width! / photo.height!
                : 1.0,
            child: photo.originalUrl != null
                ? CachedNetworkImage(
                    imageUrl: photo.originalUrl!,
                    cacheKey: '${photo.id}_original',
                    cacheManager: PhotoImageCacheManager.instance,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadOriginal(context, ref, photo),
                    icon: const Icon(Icons.download),
                    label: const Text('Download Original'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _share(context, ref, photo),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ),

          // Metadata sections
          _buildSection(
            context,
            'File Information',
            [
              _buildInfoRow('File name', photo.fileName),
              _buildInfoRow('Status', _formatStatus(photo.status)),
              if (photo.fileSize != null)
                _buildInfoRow('Size', _formatBytes(photo.fileSize!)),
              if (photo.mimeType != null)
                _buildInfoRow('Type', photo.mimeType!),
              if (photo.width != null && photo.height != null)
                _buildInfoRow('Dimensions', '${photo.width} × ${photo.height}'),
            ],
          ),

          if (photo.labels.isNotEmpty)
            _buildSection(
              context,
              'AI-Detected Labels',
              [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: photo.labels.map((label) {
                    return Chip(
                      label: Text(label.labelName),
                      avatar: CircleAvatar(
                        backgroundColor: _getConfidenceColor(label.confidence),
                        child: Text(
                          '${(label.confidence * 100).round()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          _buildSection(
            context,
            'Dates',
            [
              _buildInfoRow('Uploaded', _formatDate(photo.createdAt)),
              if (photo.processedAt != null)
                _buildInfoRow('Processed', _formatDate(photo.processedAt!)),
              if (photo.takenAt != null)
                _buildInfoRow('Taken', _formatDate(photo.takenAt!)),
            ],
          ),

          if (photo.cameraMake != null || photo.cameraModel != null)
            _buildSection(
              context,
              'Camera Information',
              [
                if (photo.cameraMake != null)
                  _buildInfoRow('Make', photo.cameraMake!),
                if (photo.cameraModel != null)
                  _buildInfoRow('Model', photo.cameraModel!),
              ],
            ),

          if (photo.gpsLatitude != null && photo.gpsLongitude != null)
            _buildSection(
              context,
              'Location',
              [
                _buildInfoRow(
                  'Coordinates',
                  '${photo.gpsLatitude}, ${photo.gpsLongitude}',
                ),
              ],
            ),

          if (photo.versions.isNotEmpty)
            _buildSection(
              context,
              'Available Versions',
              photo.versions.map((version) {
                return ListTile(
                  leading: const Icon(Icons.photo_size_select_large),
                  title: Text(_formatVersionType(version.versionType)),
                  subtitle: version.width != null && version.height != null
                      ? Text('${version.width} × ${version.height}')
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadVersion(
                      context,
                      ref,
                      photo,
                      _versionTypeToString(version.versionType),
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatStatus(PhotoStatus status) {
    switch (status) {
      case PhotoStatus.pendingProcessing:
        return 'Pending Processing';
      case PhotoStatus.processing:
        return 'Processing';
      case PhotoStatus.ready:
        return 'Ready';
      case PhotoStatus.failed:
        return 'Failed';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  String _formatVersionType(PhotoVersionType type) {
    switch (type) {
      case PhotoVersionType.thumbnail:
        return 'Thumbnail';
      case PhotoVersionType.webp640:
        return 'WebP 640px';
      case PhotoVersionType.webp1280:
        return 'WebP 1280px';
      case PhotoVersionType.webp1920:
        return 'WebP 1920px';
      case PhotoVersionType.webp2560:
        return 'WebP 2560px';
    }
  }

  String _versionTypeToString(PhotoVersionType type) {
    switch (type) {
      case PhotoVersionType.thumbnail:
        return 'THUMBNAIL';
      case PhotoVersionType.webp640:
        return 'WEBP_640';
      case PhotoVersionType.webp1280:
        return 'WEBP_1280';
      case PhotoVersionType.webp1920:
        return 'WEBP_1920';
      case PhotoVersionType.webp2560:
        return 'WEBP_2560';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.orange;
    return Colors.red;
  }

  Future<void> _downloadOriginal(
    BuildContext context,
    WidgetRef ref,
    PhotoResponse photo,
  ) async {
    final downloadService = ref.read(downloadServiceProvider);
    try {
      await downloadService.downloadPhoto(photo.id, photo.fileName);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadVersion(
    BuildContext context,
    WidgetRef ref,
    PhotoResponse photo,
    String versionType,
  ) async {
    final downloadService = ref.read(downloadServiceProvider);
    try {
      await downloadService.downloadPhoto(
        photo.id,
        '${photo.fileName}_$versionType',
        versionType: versionType,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    PhotoResponse photo,
  ) async {
    final downloadService = ref.read(downloadServiceProvider);
    try {
      await downloadService.sharePhoto(photo.id, photo.fileName);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(galleryProvider.notifier).deletePhoto(photoId);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }
}
