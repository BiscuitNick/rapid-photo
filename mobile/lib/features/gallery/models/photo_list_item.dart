import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_status.dart';

part 'photo_list_item.freezed.dart';
part 'photo_list_item.g.dart';

/// Lightweight DTO for photo list/grid view
@freezed
abstract class PhotoListItem with _$PhotoListItem {
  const factory PhotoListItem({
    required String id,
    required String fileName,
    required PhotoStatus status,
    String? thumbnailUrl,
    String? originalUrl,
    int? width,
    int? height,
    @Default([]) List<String> labels,
    @JsonKey(fromJson: _dateTimeFromEpochSeconds) required DateTime createdAt,
    @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) DateTime? takenAt,
  }) = _PhotoListItem;

  factory PhotoListItem.fromJson(Map<String, dynamic> json) =>
      _$PhotoListItemFromJson(json);
}

/// Convert Unix epoch seconds (as number) to DateTime
DateTime _dateTimeFromEpochSeconds(dynamic value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch((value * 1000).round());
  }
  if (value is String) {
    return DateTime.parse(value);
  }
  throw ArgumentError('Invalid date format: $value');
}

/// Convert Unix epoch seconds (as number) to nullable DateTime
DateTime? _dateTimeFromEpochSecondsNullable(dynamic value) {
  if (value == null) return null;
  return _dateTimeFromEpochSeconds(value);
}
