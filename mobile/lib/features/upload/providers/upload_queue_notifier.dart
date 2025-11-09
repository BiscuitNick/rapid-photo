import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:rapid_photo_mobile/features/upload/models/upload_item.dart';
import 'package:rapid_photo_mobile/features/upload/services/upload_persistence_service.dart';
import 'package:rapid_photo_mobile/features/upload/services/upload_service.dart';
import 'package:uuid/uuid.dart';

/// Notifier for managing upload queue
class UploadQueueNotifier extends AsyncNotifier<UploadQueueState> {
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  // Maximum number of parallel uploads
  static const int maxParallelUploads = 10;

  late final UploadService _uploadService;
  late final UploadPersistenceService _persistenceService;

  // Timer for periodic state persistence
  Timer? _persistenceTimer;

  @override
  Future<UploadQueueState> build() async {
    _uploadService = ref.read(uploadServiceProvider);
    _persistenceService = ref.read(uploadPersistenceServiceProvider);

    // Clean up on dispose
    ref.onDispose(() {
      _persistenceTimer?.cancel();
    });

    // Load persisted state
    final persistedState = await _persistenceService.loadQueueState();
    if (persistedState != null) {
      _logger.i('Restored ${persistedState.items.length} items from persistence');
      // Resume processing if there are queued items
      if (persistedState.queuedItems.isNotEmpty && !persistedState.isPaused) {
        _processQueue();
      }
      return persistedState;
    }

    return const UploadQueueState();
  }

  /// Add files to the upload queue
  Future<void> addFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    final currentState = state.value ?? const UploadQueueState();
    final newItems = <UploadItem>[];

    for (final file in files) {
      final id = _uuid.v4();
      final fileSize = await file.length();

      final item = UploadItem(
        id: id,
        localPath: file.path,
        fileName: file.name,
        fileSize: fileSize,
        mimeType: file.mimeType ?? 'image/jpeg',
        status: UploadStatus.queued,
        queuedAt: DateTime.now(),
      );

      newItems.add(item);
    }

    final updatedState = currentState.copyWith(
      items: [...currentState.items, ...newItems],
    );

    state = AsyncData(updatedState);
    await _persistState();

    _logger.i('Added ${newItems.length} files to upload queue');

    // Start processing queue if not paused
    if (!updatedState.isPaused) {
      _processQueue();
    }
  }

  /// Process the upload queue
  Future<void> _processQueue() async {
    final currentState = state.value;
    if (currentState == null || currentState.isPaused || currentState.isProcessing) {
      return;
    }

    // Mark as processing
    state = AsyncData(currentState.copyWith(isProcessing: true));

    try {
      while (true) {
        final currentState = state.value;
        if (currentState == null || currentState.isPaused) break;

        final queuedItems = currentState.queuedItems;
        final uploadingCount = currentState.uploadingItems.length;

        // No more items to process
        if (queuedItems.isEmpty && uploadingCount == 0) {
          _logger.i('Queue processing complete');
          break;
        }

        // Calculate how many new uploads we can start
        final availableSlots = maxParallelUploads - uploadingCount;
        if (availableSlots <= 0) {
          // Wait for some uploads to complete
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // Get items to upload in this batch
        final batch = queuedItems.take(availableSlots).toList();
        if (batch.isEmpty) {
          // No queued items, but uploads are in progress
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        // Start uploads in parallel
        await Future.wait(
          batch.map((item) => _uploadItem(item)),
        );
      }
    } catch (e) {
      _logger.e('Error processing queue: $e');
    } finally {
      // Mark as not processing
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncData(currentState.copyWith(isProcessing: false));
        await _persistState();
      }
    }
  }

  /// Upload a single item
  Future<void> _uploadItem(UploadItem item) async {
    try {
      _logger.d('Starting upload for ${item.fileName}');

      // Update status to uploading
      _updateItemStatus(item.id, UploadStatus.uploading, startedAt: DateTime.now());

      // Step 1: Generate presigned URL
      final presignedResponse = await _uploadService.generatePresignedUrl(
        fileName: item.fileName,
        fileSize: item.fileSize,
        mimeType: item.mimeType,
      );

      // Update item with presigned URL info
      _updateItem(
        item.id,
        uploadJobId: presignedResponse.uploadJobId,
        presignedUrl: presignedResponse.presignedUrl,
        s3Key: presignedResponse.s3Key,
      );

      // Step 2: Upload to S3
      final file = File(item.localPath);
      final etag = await _uploadService.uploadToS3(
        presignedUrl: presignedResponse.presignedUrl,
        file: file,
        mimeType: item.mimeType,
        onProgress: (progress) {
          _updateItemProgress(item.id, progress);
        },
      );

      // Update item with ETag
      _updateItem(item.id, etag: etag);

      // Step 3: Confirm upload
      await _uploadService.confirmUpload(
        uploadId: presignedResponse.uploadId,
        etag: etag,
      );

      // Update status to processing (backend will process the image)
      _updateItemStatus(
        item.id,
        UploadStatus.processing,
        progress: 1.0,
      );

      // For now, mark as complete after a short delay
      // In production, this would be updated by polling or push notifications
      await Future.delayed(const Duration(seconds: 2));
      _updateItemStatus(
        item.id,
        UploadStatus.complete,
        completedAt: DateTime.now(),
      );

      _logger.i('Upload complete for ${item.fileName}');
    } catch (e) {
      _logger.e('Upload failed for ${item.fileName}: $e');
      _updateItemStatus(
        item.id,
        UploadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update item status
  void _updateItemStatus(
    String itemId,
    UploadStatus status, {
    double? progress,
    String? errorMessage,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          status: status,
          progress: progress ?? item.progress,
          errorMessage: errorMessage,
          startedAt: startedAt ?? item.startedAt,
          completedAt: completedAt ?? item.completedAt,
        );
      }
      return item;
    }).toList();

    final activeUploads = items.where((i) => i.status == UploadStatus.uploading).length;

    state = AsyncData(
      currentState.copyWith(
        items: items,
        activeUploads: activeUploads,
      ),
    );

    _schedulePersistedState();
  }

  /// Update item progress
  void _updateItemProgress(String itemId, double progress) {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(progress: progress);
      }
      return item;
    }).toList();

    state = AsyncData(currentState.copyWith(items: items));
  }

  /// Update item with additional data
  void _updateItem(
    String itemId, {
    String? uploadJobId,
    String? presignedUrl,
    String? s3Key,
    String? etag,
  }) {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          uploadJobId: uploadJobId ?? item.uploadJobId,
          presignedUrl: presignedUrl ?? item.presignedUrl,
          s3Key: s3Key ?? item.s3Key,
          etag: etag ?? item.etag,
        );
      }
      return item;
    }).toList();

    state = AsyncData(currentState.copyWith(items: items));
  }

  /// Pause queue processing
  Future<void> pauseQueue() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(isPaused: true));
    await _persistState();
    _logger.i('Upload queue paused');
  }

  /// Resume queue processing
  Future<void> resumeQueue() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncData(currentState.copyWith(isPaused: false));
    await _persistState();
    _logger.i('Upload queue resumed');

    // Start processing
    _processQueue();
  }

  /// Retry failed uploads
  Future<void> retryFailed() async {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items.map((item) {
      if (item.status == UploadStatus.failed) {
        return item.copyWith(
          status: UploadStatus.queued,
          progress: 0.0,
          errorMessage: null,
        );
      }
      return item;
    }).toList();

    state = AsyncData(currentState.copyWith(items: items));
    await _persistState();

    _logger.i('Retrying ${currentState.failedItems.length} failed uploads');

    if (!currentState.isPaused) {
      _processQueue();
    }
  }

  /// Remove an item from the queue
  Future<void> removeItem(String itemId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items.where((item) => item.id != itemId).toList();
    state = AsyncData(currentState.copyWith(items: items));
    await _persistState();

    _logger.i('Removed item $itemId from queue');
  }

  /// Clear completed items
  Future<void> clearCompleted() async {
    final currentState = state.value;
    if (currentState == null) return;

    final items = currentState.items
        .where((item) => item.status != UploadStatus.complete)
        .toList();

    state = AsyncData(currentState.copyWith(items: items));
    await _persistState();

    _logger.i('Cleared completed items');
  }

  /// Persist state to storage
  Future<void> _persistState() async {
    final currentState = state.value;
    if (currentState != null) {
      await _persistenceService.saveQueueState(currentState);
    }
  }

  /// Schedule state persistence (debounced)
  void _schedulePersistedState() {
    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(const Duration(milliseconds: 500), () {
      _persistState();
    });
  }
}

/// Provider for upload queue notifier
final uploadQueueProvider =
    AsyncNotifierProvider<UploadQueueNotifier, UploadQueueState>(
  () => UploadQueueNotifier(),
);
