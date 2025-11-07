import 'package:json_annotation/json_annotation.dart';

/// Status of photo processing lifecycle
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum PhotoStatus {
  /// Photo uploaded, waiting for Lambda processing
  pendingProcessing,

  /// Lambda is processing the photo
  processing,

  /// Photo fully processed and available
  ready,

  /// Processing failed
  failed,
}
