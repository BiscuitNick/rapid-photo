// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoLabel _$PhotoLabelFromJson(Map<String, dynamic> json) => _PhotoLabel(
      labelName: json['labelName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      confidenceLevel: json['confidenceLevel'] as String,
    );

Map<String, dynamic> _$PhotoLabelToJson(_PhotoLabel instance) =>
    <String, dynamic>{
      'labelName': instance.labelName,
      'confidence': instance.confidence,
      'confidenceLevel': instance.confidenceLevel,
    };
