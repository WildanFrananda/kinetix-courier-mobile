// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_challenge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TwoFactorChallenge _$TwoFactorChallengeFromJson(Map<String, dynamic> json) =>
    _TwoFactorChallenge(
      challengeToken: json['challengeToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
    );

Map<String, dynamic> _$TwoFactorChallengeToJson(_TwoFactorChallenge instance) =>
    <String, dynamic>{
      'challengeToken': instance.challengeToken,
      'expiresIn': instance.expiresIn,
    };
