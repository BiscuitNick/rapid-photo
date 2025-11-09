// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoListItem _$PhotoListItemFromJson(Map<String, dynamic> json) =>
    _PhotoListItem(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      status: $enumDecode(_$PhotoStatusEnumMap, json['status']),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      originalUrl: json['originalUrl'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: _dateTimeFromEpochSeconds(json['createdAt']),
      takenAt: _dateTimeFromEpochSecondsNullable(json['takenAt']),
    );

Map<String, dynamic> _$PhotoListItemToJson(_PhotoListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'status': _$PhotoStatusEnumMap[instance.status]!,
      'thumbnailUrl': instance.thumbnailUrl,
      'originalUrl': instance.originalUrl,
      'width': instance.width,
      'height': instance.height,
      'labels': instance.labels,
      'createdAt': instance.createdAt.toIso8601String(),
      'takenAt': instance.takenAt?.toIso8601String(),
    };

const _$PhotoStatusEnumMap = {
  PhotoStatus.pendingProcessing: 'PENDING_PROCESSING',
  PhotoStatus.processing: 'PROCESSING',
  PhotoStatus.ready: 'READY',
  PhotoStatus.failed: 'FAILED',
};
