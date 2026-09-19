import 'package:freezed_annotation/freezed_annotation.dart';

part 'authenticated_account.freezed.dart';
part 'authenticated_account.g.dart';

@freezed
abstract class AuthenticatedAccount with _$AuthenticatedAccount {
  const factory AuthenticatedAccount({
    required int id,
    required String email,
    required String role,
    required String principalId,
  }) = _AuthenticatedAccount;

  factory AuthenticatedAccount.fromJson(Map<String, dynamic> json) =>
      _$AuthenticatedAccountFromJson(json);
}
