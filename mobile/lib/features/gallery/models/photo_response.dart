import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_label.dart';
import 'photo_status.dart';
import 'photo_version.dart';

part 'photo_response.freezed.dart';
part 'photo_response.g.dart';

/// Detailed photo response with all metadata and versions
@freezed
class PhotoResponse with _$PhotoResponse {
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
    required DateTime createdAt,
    DateTime? processedAt,
    DateTime? takenAt,
    String? cameraMake,
    String? cameraModel,
    double? gpsLatitude,
    double? gpsLongitude,
  }) = _PhotoResponse;

  factory PhotoResponse.fromJson(Map<String, dynamic> json) =>
      _$PhotoResponseFromJson(json);
}
