import 'package:freezed_annotation/freezed_annotation.dart';

part 'upload_item.freezed.dart';
part 'upload_item.g.dart';

/// Status of an upload item
enum UploadStatus {
  queued,
  uploading,
  processing,
  complete,
  failed,
  cancelled,
}

/// Represents a single file upload
@freezed
abstract class UploadItem with _$UploadItem {
  

  const factory UploadItem({
    required String id,
    required String localPath,
    required String fileName,
    required int fileSize,
    required String mimeType,
    @Default(UploadStatus.queued) UploadStatus status,
    @Default(0.0) double progress,
    String? uploadJobId,
    String? s3Key,
    String? presignedUrl,
    String? etag,
    String? errorMessage,
    DateTime? queuedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) = _UploadItem;

  factory UploadItem.fromJson(Map<String, dynamic> json) =>
      _$UploadItemFromJson(json);
}

/// State of the upload queue
@freezed
abstract class UploadQueueState with _$UploadQueueState {
  

  const factory UploadQueueState({
    @Default([]) List<UploadItem> items,
    @Default(0) int activeUploads,
    @Default(false) bool isPaused,
    @Default(false) bool isProcessing,
  }) = _UploadQueueState;

  factory UploadQueueState.fromJson(Map<String, dynamic> json) =>
      _$UploadQueueStateFromJson(json);
}

extension UploadQueueStateExtensions on UploadQueueState {
  /// Get items by status
  List<UploadItem> itemsByStatus(UploadStatus status) {
    return items.where((item) => item.status == status).toList();
  }

  /// Get queued items
  List<UploadItem> get queuedItems => itemsByStatus(UploadStatus.queued);

  /// Get uploading items
  List<UploadItem> get uploadingItems => itemsByStatus(UploadStatus.uploading);

  /// Get processing items
  List<UploadItem> get processingItems =>
      itemsByStatus(UploadStatus.processing);

  /// Get completed items
  List<UploadItem> get completedItems => itemsByStatus(UploadStatus.complete);

  /// Get failed items
  List<UploadItem> get failedItems => itemsByStatus(UploadStatus.failed);

  /// Get total progress
  double get totalProgress {
    if (items.isEmpty) return 0.0;
    final total = items.fold<double>(
      0.0,
      (sum, item) => sum + item.progress,
    );
    return total / items.length;
  }

  /// Check if queue is empty
  bool get isEmpty => items.isEmpty;

  /// Check if all items are complete or failed
  bool get isComplete {
    return items.isNotEmpty &&
        items.every(
          (item) =>
              item.status == UploadStatus.complete ||
              item.status == UploadStatus.failed ||
              item.status == UploadStatus.cancelled,
        );
  }
}
