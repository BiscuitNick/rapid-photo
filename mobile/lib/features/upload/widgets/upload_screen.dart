import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rapid_photo_mobile/features/upload/models/upload_item.dart';
import 'package:rapid_photo_mobile/features/upload/providers/upload_queue_notifier.dart';
import 'package:rapid_photo_mobile/features/upload/widgets/upload_progress_card.dart';

/// Upload screen with Material 3 design
class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  UploadStatusFilter _filter = UploadStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    final uploadQueueAsync = ref.watch(uploadQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: uploadQueueAsync.when(
        data: (state) => _buildContent(context, state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(uploadQueueProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickImages(context),
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('Add Photos'),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UploadQueueState state) {
    final filteredItems = _getFilteredItems(state);

    return Column(
      children: [
        // Filter chips
        _buildFilterBar(state),

        // Progress summary
        if (state.items.isNotEmpty) _buildProgressSummary(state),

        // Control buttons
        if (state.items.isNotEmpty) _buildControlButtons(state),

        const Divider(height: 1),

        // Upload list
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: filteredItems.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return UploadProgressCard(
                      item: item,
                      onRetry: () => _retryItem(item),
                      onRemove: () => _removeItem(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(UploadQueueState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<UploadStatusFilter>(
        segments: [
          ButtonSegment(
            value: UploadStatusFilter.all,
            label: Text('All (${state.items.length})'),
            icon: const Icon(Icons.list),
          ),
          ButtonSegment(
            value: UploadStatusFilter.uploading,
            label: Text('Uploading (${state.uploadingItems.length})'),
            icon: const Icon(Icons.cloud_upload),
          ),
          ButtonSegment(
            value: UploadStatusFilter.complete,
            label: Text('Complete (${state.completedItems.length})'),
            icon: const Icon(Icons.check_circle),
          ),
          ButtonSegment(
            value: UploadStatusFilter.failed,
            label: Text('Failed (${state.failedItems.length})'),
            icon: const Icon(Icons.error),
          ),
        ],
        selected: {_filter},
        onSelectionChanged: (Set<UploadStatusFilter> newSelection) {
          setState(() {
            _filter = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildProgressSummary(UploadQueueState state) {
    final totalProgress = state.totalProgress;
    final completedCount = state.completedItems.length;
    final totalCount = state.items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress: $completedCount / $totalCount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${(totalProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalProgress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(UploadQueueState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Pause/Resume button
          FilledButton.tonalIcon(
            onPressed: state.isPaused
                ? () => ref.read(uploadQueueProvider.notifier).resumeQueue()
                : () => ref.read(uploadQueueProvider.notifier).pauseQueue(),
            icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
            label: Text(state.isPaused ? 'Resume' : 'Pause'),
          ),
          const SizedBox(width: 8),

          // Retry failed button
          if (state.failedItems.isNotEmpty)
            FilledButton.tonalIcon(
              onPressed: () =>
                  ref.read(uploadQueueProvider.notifier).retryFailed(),
              icon: const Icon(Icons.refresh),
              label: Text('Retry Failed (${state.failedItems.length})'),
            ),
          const Spacer(),

          // Clear completed button
          if (state.completedItems.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(uploadQueueProvider.notifier).clearCompleted(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Completed'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No uploads yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add photos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  List<UploadItem> _getFilteredItems(UploadQueueState state) {
    switch (_filter) {
      case UploadStatusFilter.all:
        return state.items;
      case UploadStatusFilter.uploading:
        return state.uploadingItems +
            state.queuedItems +
            state.processingItems;
      case UploadStatusFilter.complete:
        return state.completedItems;
      case UploadStatusFilter.failed:
        return state.failedItems;
    }
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 100,
      );

      if (images.isEmpty) return;

      if (!mounted) return;

      // Check if adding too many files
      if (images.length > 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 100 photos can be uploaded at once'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Add files to queue
      await ref.read(uploadQueueProvider.notifier).addFiles(images);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${images.length} photos to upload queue'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _retryItem(UploadItem item) async {
    // Update the item to queued status and it will be picked up by the queue processor
    // This is handled by the retryFailed method, but for individual items we can do:
    // For now, we'll just call retryFailed which retries all failed items
    await ref.read(uploadQueueProvider.notifier).retryFailed();
  }

  Future<void> _removeItem(UploadItem item) async {
    await ref.read(uploadQueueProvider.notifier).removeItem(item.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${item.fileName}'),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Upload up to 100 photos at once'),
            SizedBox(height: 8),
            Text('• Maximum 10 uploads run in parallel'),
            SizedBox(height: 8),
            Text('• Uploads continue in the background'),
            SizedBox(height: 8),
            Text('• Queue state is saved automatically'),
            SizedBox(height: 8),
            Text('• You can pause/resume uploads anytime'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Upload status filter enum
enum UploadStatusFilter {
  all,
  uploading,
  complete,
  failed,
}
