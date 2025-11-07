import 'package:json_annotation/json_annotation.dart';

/// Types of processed photo versions
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum PhotoVersionType {
  /// 300x300 center crop thumbnail
  thumbnail,

  /// 640px wide WebP
  webp640,

  /// 1280px wide WebP
  webp1280,

  /// 1920px wide WebP
  webp1920,

  /// 2560px wide WebP
  webp2560,
}
