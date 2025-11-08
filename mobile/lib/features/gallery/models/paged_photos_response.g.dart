// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged_photos_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PagedPhotosResponse _$PagedPhotosResponseFromJson(Map<String, dynamic> json) =>
    _PagedPhotosResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => PhotoListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );

Map<String, dynamic> _$PagedPhotosResponseToJson(
        _PagedPhotosResponse instance) =>
    <String, dynamic>{
      'content': instance.content,
      'page': instance.page,
      'size': instance.size,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
      'hasPrevious': instance.hasPrevious,
    };
