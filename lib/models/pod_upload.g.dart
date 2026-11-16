// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pod_upload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PodUpload _$PodUploadFromJson(Map<String, dynamic> json) => _PodUpload(
  uploadUrl: json['uploadUrl'] as String,
  photoUrl: json['photoUrl'] as String,
  uploadHeaders:
      (json['uploadHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
);

Map<String, dynamic> _$PodUploadToJson(_PodUpload instance) =>
    <String, dynamic>{
      'uploadUrl': instance.uploadUrl,
      'photoUrl': instance.photoUrl,
      'uploadHeaders': instance.uploadHeaders,
    };
