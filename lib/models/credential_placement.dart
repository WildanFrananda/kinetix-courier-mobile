import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential_placement.freezed.dart';

@freezed
abstract class CredentialPlacement with _$CredentialPlacement {
  const factory CredentialPlacement({
    required int generation,
    required String contractAddress,
    required String leafIndex,
  }) = _CredentialPlacement;
}
