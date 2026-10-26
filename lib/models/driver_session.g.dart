// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverSession _$DriverSessionFromJson(Map<String, dynamic> json) =>
    _DriverSession(
      driverId: _$JsonConverterFromJson<int, DriverId>(
        json['driver_id'],
        const DriverIdConverter().fromJson,
      ),
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$DriverSessionToJson(_DriverSession instance) =>
    <String, dynamic>{
      'driver_id': _$JsonConverterToJson<int, DriverId>(
        instance.driverId,
        const DriverIdConverter().toJson,
      ),
      'token': instance.token,
      'refresh_token': instance.refreshToken,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
