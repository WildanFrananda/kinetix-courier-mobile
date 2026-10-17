import 'package:freezed_annotation/freezed_annotation.dart';

part 'pod_upload.freezed.dart';
part 'pod_upload.g.dart';

@freezed
abstract class PodUpload with _$PodUpload {
  const factory PodUpload({
    @JsonKey(name: 'upload_url') required String uploadUrl,
    @JsonKey(name: 'photo_url') required String photoUrl,
    @JsonKey(name: 'upload_headers')
    @Default(<String, String>{})
    Map<String, String> uploadHeaders,
  }) = _PodUpload;

  factory PodUpload.fromJson(Map<String, dynamic> json) =>
      _$PodUploadFromJson(json);
}
