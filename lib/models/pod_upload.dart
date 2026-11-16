import 'package:freezed_annotation/freezed_annotation.dart';

part 'pod_upload.freezed.dart';
part 'pod_upload.g.dart';

@freezed
abstract class PodUpload with _$PodUpload {
  const factory PodUpload({
    required String uploadUrl,
    required String photoUrl,
    @Default(<String, String>{}) Map<String, String> uploadHeaders,
  }) = _PodUpload;

  factory PodUpload.fromJson(Map<String, dynamic> json) =>
      _$PodUploadFromJson(json);
}
