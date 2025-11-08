// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UploadItem _$UploadItemFromJson(Map<String, dynamic> json) => _UploadItem(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      fileName: json['fileName'] as String,
      fileSize: (json['fileSize'] as num).toInt(),
      mimeType: json['mimeType'] as String,
      status: $enumDecodeNullable(_$UploadStatusEnumMap, json['status']) ??
          UploadStatus.queued,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      uploadJobId: json['uploadJobId'] as String?,
      s3Key: json['s3Key'] as String?,
      presignedUrl: json['presignedUrl'] as String?,
      etag: json['etag'] as String?,
      errorMessage: json['errorMessage'] as String?,
      queuedAt: json['queuedAt'] == null
          ? null
          : DateTime.parse(json['queuedAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$UploadItemToJson(_UploadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'localPath': instance.localPath,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'status': _$UploadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'uploadJobId': instance.uploadJobId,
      's3Key': instance.s3Key,
      'presignedUrl': instance.presignedUrl,
      'etag': instance.etag,
      'errorMessage': instance.errorMessage,
      'queuedAt': instance.queuedAt?.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$UploadStatusEnumMap = {
  UploadStatus.queued: 'queued',
  UploadStatus.uploading: 'uploading',
  UploadStatus.processing: 'processing',
  UploadStatus.complete: 'complete',
  UploadStatus.failed: 'failed',
  UploadStatus.cancelled: 'cancelled',
};

_UploadQueueState _$UploadQueueStateFromJson(Map<String, dynamic> json) =>
    _UploadQueueState(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => UploadItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      activeUploads: (json['activeUploads'] as num?)?.toInt() ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      isProcessing: json['isProcessing'] as bool? ?? false,
    );

Map<String, dynamic> _$UploadQueueStateToJson(_UploadQueueState instance) =>
    <String, dynamic>{
      'items': instance.items,
      'activeUploads': instance.activeUploads,
      'isPaused': instance.isPaused,
      'isProcessing': instance.isProcessing,
    };
