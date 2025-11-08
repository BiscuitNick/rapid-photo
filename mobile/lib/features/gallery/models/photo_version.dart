import 'package:freezed_annotation/freezed_annotation.dart';
import 'photo_version_type.dart';

part 'photo_version.freezed.dart';
part 'photo_version.g.dart';

/// DTO for photo version information with URL
@freezed
abstract class PhotoVersion with _$PhotoVersion {
  

  const factory PhotoVersion({
    required PhotoVersionType versionType,
    required String url,
    int? width,
    int? height,
    int? fileSize,
    String? mimeType,
  }) = _PhotoVersion;

  factory PhotoVersion.fromJson(Map<String, dynamic> json) =>
      _$PhotoVersionFromJson(json);
}
