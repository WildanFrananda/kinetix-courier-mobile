import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_verify_request.freezed.dart';
part 'two_factor_verify_request.g.dart';

@freezed
abstract class TwoFactorVerifyRequest with _$TwoFactorVerifyRequest {
  const factory TwoFactorVerifyRequest({
    required String challengeToken,
    required String code,
  }) = _TwoFactorVerifyRequest;

  factory TwoFactorVerifyRequest.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorVerifyRequestFromJson(json);
}
