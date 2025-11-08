// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GalleryState _$GalleryStateFromJson(Map<String, dynamic> json) =>
    _GalleryState(
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => PhotoListItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      currentPage: (json['currentPage'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? true,
      totalPhotos: (json['totalPhotos'] as num?)?.toInt() ?? 0,
      filterTags: (json['filterTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sortBy: json['sortBy'] as String?,
      sortDirection: json['sortDirection'] as String? ?? 'desc',
      isLoading: json['isLoading'] as bool? ?? false,
      isRefreshing: json['isRefreshing'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$GalleryStateToJson(_GalleryState instance) =>
    <String, dynamic>{
      'photos': instance.photos,
      'currentPage': instance.currentPage,
      'hasMore': instance.hasMore,
      'totalPhotos': instance.totalPhotos,
      'filterTags': instance.filterTags,
      'sortBy': instance.sortBy,
      'sortDirection': instance.sortDirection,
      'isLoading': instance.isLoading,
      'isRefreshing': instance.isRefreshing,
      'error': instance.error,
    };
