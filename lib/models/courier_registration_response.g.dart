// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_registration_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CourierRegistrationResponse _$CourierRegistrationResponseFromJson(
  Map<String, dynamic> json,
) => _CourierRegistrationResponse(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresIn: (json['expiresIn'] as num).toInt(),
  tokenType: json['tokenType'] as String,
  user: AuthenticatedAccount.fromJson(json['user'] as Map<String, dynamic>),
  driverId: const DriverIdConverter().fromJson(
    (json['driverId'] as num).toInt(),
  ),
);

Map<String, dynamic> _$CourierRegistrationResponseToJson(
  _CourierRegistrationResponse instance,
) => <String, dynamic>{
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
  'expiresIn': instance.expiresIn,
  'tokenType': instance.tokenType,
  'user': instance.user,
  'driverId': const DriverIdConverter().toJson(instance.driverId),
};
