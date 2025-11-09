import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_label.dart';
import 'photo_status.dart';
import 'photo_version.dart';

part 'photo_response.freezed.dart';
part 'photo_response.g.dart';

/// Detailed photo response with all metadata and versions
@freezed
abstract class PhotoResponse with _$PhotoResponse {
  

  const factory PhotoResponse({
    required String id,
    required String fileName,
    required PhotoStatus status,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    String? originalUrl,
    String? thumbnailUrl,
    @Default([]) List<PhotoVersion> versions,
    @Default([]) List<PhotoLabel> labels,
    @JsonKey(fromJson: _dateTimeFromEpochSeconds) required DateTime createdAt,
    @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) DateTime? processedAt,
    @JsonKey(fromJson: _dateTimeFromEpochSecondsNullable) DateTime? takenAt,
    String? cameraMake,
    String? cameraModel,
    double? gpsLatitude,
    double? gpsLongitude,
  }) = _PhotoResponse;

  factory PhotoResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoResponseFromJson(json);
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
