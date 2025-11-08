// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PhotoVersion _$PhotoVersionFromJson(Map<String, dynamic> json) =>
    _PhotoVersion(
      versionType: $enumDecode(_$PhotoVersionTypeEnumMap, json['versionType']),
      url: json['url'] as String,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
    );

Map<String, dynamic> _$PhotoVersionToJson(_PhotoVersion instance) =>
    <String, dynamic>{
      'versionType': _$PhotoVersionTypeEnumMap[instance.versionType]!,
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
    };

const _$PhotoVersionTypeEnumMap = {
  PhotoVersionType.thumbnail: 'THUMBNAIL',
  PhotoVersionType.webp640: 'WEBP640',
  PhotoVersionType.webp1280: 'WEBP1280',
  PhotoVersionType.webp1920: 'WEBP1920',
  PhotoVersionType.webp2560: 'WEBP2560',
};
