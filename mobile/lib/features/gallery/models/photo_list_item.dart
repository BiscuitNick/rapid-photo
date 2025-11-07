import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_status.dart';

part 'photo_list_item.freezed.dart';
part 'photo_list_item.g.dart';

/// Lightweight DTO for photo list/grid view
@freezed
class PhotoListItem with _$PhotoListItem {
  const factory PhotoListItem({
    required String id,
    required String fileName,
    required PhotoStatus status,
    required String thumbnailUrl,
    int? width,
    int? height,
    @Default([]) List<String> labels,
    required DateTime createdAt,
    DateTime? takenAt,
  }) = _PhotoListItem;

  factory PhotoListItem.fromJson(Map<String, dynamic> json) =>
      _$PhotoListItemFromJson(json);
}
