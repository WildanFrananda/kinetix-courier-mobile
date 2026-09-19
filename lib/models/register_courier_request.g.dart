// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_courier_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RegisterCourierRequest _$RegisterCourierRequestFromJson(
  Map<String, dynamic> json,
) => _RegisterCourierRequest(
  email: json['email'] as String,
  password: json['password'] as String,
  fullName: json['fullName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  vehiclePlate: json['vehiclePlate'] as String,
  capacityKg: (json['capacityKg'] as num).toInt(),
);

Map<String, dynamic> _$RegisterCourierRequestToJson(
  _RegisterCourierRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
  'fullName': instance.fullName,
  'phoneNumber': instance.phoneNumber,
  'vehiclePlate': instance.vehiclePlate,
  'capacityKg': instance.capacityKg,
};
