import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_label.freezed.dart';
part 'photo_label.g.dart';

/// DTO for photo label (AI-detected tag)
@freezed
class PhotoLabel with _$PhotoLabel {
  const factory PhotoLabel({
    required String labelName,
    required double confidence,
    required String confidenceLevel,
  }) = _PhotoLabel;

  factory PhotoLabel.fromJson(Map<String, dynamic> json) =>
      _$PhotoLabelFromJson(json);
}
