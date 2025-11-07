import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rapid_photo_mobile/features/upload/models/upload_item.dart';

/// Card displaying upload progress for a single item
class UploadProgressCard extends StatelessWidget {
  final UploadItem item;
  final VoidCallback? onRetry;
  final VoidCallback? onRemove;

  const UploadProgressCard({
    super.key,
    required this.item,
    this.onRetry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      elevation: 1,
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File name
                    Text(
                      item.fileName,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // File size
                    Text(
                      _formatFileSize(item.fileSize),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar (for uploading status)
                    if (item.status == UploadStatus.uploading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(item.progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),

                    // Status chip
                    const SizedBox(height: 8),
                    _buildStatusChip(context),

                    // Error message
                    if (item.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: item.localPath.isNotEmpty && File(item.localPath).existsSync()
            ? Image.file(
                File(item.localPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              )
            : const Icon(Icons.image, color: Colors.grey),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final (icon, label, color) = _getStatusInfo();

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      side: BorderSide(color: color.withOpacity(0.3)),
      backgroundColor: color.withOpacity(0.1),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  (IconData, String, Color) _getStatusInfo() {
    switch (item.status) {
      case UploadStatus.queued:
        return (Icons.schedule, 'Queued', Colors.blue);
      case UploadStatus.uploading:
        return (Icons.cloud_upload, 'Uploading', Colors.orange);
      case UploadStatus.processing:
        return (Icons.hourglass_bottom, 'Processing', Colors.purple);
      case UploadStatus.complete:
        return (Icons.check_circle, 'Complete', Colors.green);
      case UploadStatus.failed:
        return (Icons.error, 'Failed', Colors.red);
      case UploadStatus.cancelled:
        return (Icons.cancel, 'Cancelled', Colors.grey);
    }
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'retry':
            onRetry?.call();
            break;
          case 'remove':
            onRemove?.call();
            break;
          case 'details':
            _showDetails(context);
            break;
        }
      },
      itemBuilder: (context) => [
        if (item.status == UploadStatus.failed)
          const PopupMenuItem(
            value: 'retry',
            child: Row(
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text('Retry'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Details'),
            ],
          ),
        ),
        if (item.status != UploadStatus.uploading)
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Remove', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow(label: 'File Name', value: item.fileName),
              _DetailRow(label: 'File Size', value: _formatFileSize(item.fileSize)),
              _DetailRow(label: 'MIME Type', value: item.mimeType),
              _DetailRow(label: 'Status', value: item.status.name),
              if (item.progress > 0)
                _DetailRow(
                  label: 'Progress',
                  value: '${(item.progress * 100).toStringAsFixed(1)}%',
                ),
              if (item.uploadJobId != null)
                _DetailRow(label: 'Upload Job ID', value: item.uploadJobId!),
              if (item.s3Key != null) _DetailRow(label: 'S3 Key', value: item.s3Key!),
              if (item.queuedAt != null)
                _DetailRow(
                  label: 'Queued At',
                  value: _formatDateTime(item.queuedAt!),
                ),
              if (item.startedAt != null)
                _DetailRow(
                  label: 'Started At',
                  value: _formatDateTime(item.startedAt!),
                ),
              if (item.completedAt != null)
                _DetailRow(
                  label: 'Completed At',
                  value: _formatDateTime(item.completedAt!),
                ),
              if (item.errorMessage != null)
                _DetailRow(
                  label: 'Error',
                  value: item.errorMessage!,
                  valueColor: Colors.red,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
