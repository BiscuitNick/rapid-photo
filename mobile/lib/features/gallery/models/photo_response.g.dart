// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoResponse _$PhotoResponseFromJson(Map<String, dynamic> json) =>
    _PhotoResponse(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      status: $enumDecode(_$PhotoStatusEnumMap, json['status']),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      originalUrl: json['originalUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      versions: (json['versions'] as List<dynamic>?)
              ?.map((e) => PhotoVersion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => PhotoLabel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: _dateTimeFromEpochSeconds(json['createdAt']),
      processedAt: _dateTimeFromEpochSecondsNullable(json['processedAt']),
      takenAt: _dateTimeFromEpochSecondsNullable(json['takenAt']),
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      gpsLatitude: (json['gpsLatitude'] as num?)?.toDouble(),
      gpsLongitude: (json['gpsLongitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PhotoResponseToJson(_PhotoResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'status': _$PhotoStatusEnumMap[instance.status]!,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'width': instance.width,
      'height': instance.height,
      'originalUrl': instance.originalUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'versions': instance.versions,
      'labels': instance.labels,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'takenAt': instance.takenAt?.toIso8601String(),
      'cameraMake': instance.cameraMake,
      'cameraModel': instance.cameraModel,
      'gpsLatitude': instance.gpsLatitude,
      'gpsLongitude': instance.gpsLongitude,
    };

const _$PhotoStatusEnumMap = {
  PhotoStatus.pendingProcessing: 'PENDING_PROCESSING',
  PhotoStatus.processing: 'PROCESSING',
  PhotoStatus.ready: 'READY',
  PhotoStatus.failed: 'FAILED',
};
