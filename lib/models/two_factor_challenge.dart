import 'package:freezed_annotation/freezed_annotation.dart';

part 'two_factor_challenge.freezed.dart';
part 'two_factor_challenge.g.dart';

@freezed
abstract class TwoFactorChallenge with _$TwoFactorChallenge {
  const factory TwoFactorChallenge({
    required String challengeToken,
    required int expiresIn,
  }) = _TwoFactorChallenge;

  factory TwoFactorChallenge.fromJson(Map<String, dynamic> json) =>
      _$TwoFactorChallengeFromJson(json);
}
