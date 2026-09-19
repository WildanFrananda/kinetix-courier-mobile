// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authenticated_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthenticatedAccount _$AuthenticatedAccountFromJson(
  Map<String, dynamic> json,
) => _AuthenticatedAccount(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  role: json['role'] as String,
  principalId: json['principalId'] as String,
);

Map<String, dynamic> _$AuthenticatedAccountToJson(
  _AuthenticatedAccount instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'role': instance.role,
  'principalId': instance.principalId,
};
