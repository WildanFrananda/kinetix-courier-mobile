// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_verify_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwoFactorVerifyRequest _$TwoFactorVerifyRequestFromJson(
  Map<String, dynamic> json,
) => _TwoFactorVerifyRequest(
  challengeToken: json['challengeToken'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$TwoFactorVerifyRequestToJson(
  _TwoFactorVerifyRequest instance,
) => <String, dynamic>{
  'challengeToken': instance.challengeToken,
  'code': instance.code,
};
