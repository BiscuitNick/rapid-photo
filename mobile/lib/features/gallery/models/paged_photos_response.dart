import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_list_item.dart';

part 'paged_photos_response.freezed.dart';
part 'paged_photos_response.g.dart';

/// Paginated response for photo listings
@freezed
abstract class PagedPhotosResponse with _$PagedPhotosResponse {
  

  const factory PagedPhotosResponse({
    @Default([]) List<PhotoListItem> content,
    @Default(0) int page,
    @Default(20) int size,
    @Default(0) int totalElements,
    @Default(0) int totalPages,
    @Default(false) bool hasNext,
    @Default(false) bool hasPrevious,
  }) = _PagedPhotosResponse;

  factory PagedPhotosResponse.fromJson(Map<String, dynamic> json) =>
      _$PagedPhotosResponseFromJson(json);
}
