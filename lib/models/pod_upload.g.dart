// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pod_upload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PodUpload _$PodUploadFromJson(Map<String, dynamic> json) => _PodUpload(
  uploadUrl: json['upload_url'] as String,
  photoUrl: json['photo_url'] as String,
  uploadHeaders:
      (json['upload_headers'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
);

Map<String, dynamic> _$PodUploadToJson(_PodUpload instance) =>
    <String, dynamic>{
      'upload_url': instance.uploadUrl,
      'photo_url': instance.photoUrl,
      'upload_headers': instance.uploadHeaders,
    };
