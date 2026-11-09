// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DriverProfile _$DriverProfileFromJson(Map<String, dynamic> json) =>
    _DriverProfile(
      id: const DriverIdConverter().fromJson((json['id'] as num).toInt()),
      vehiclePlate: json['vehicle_plate'] as String,
      capacityKg: (json['capacity_kg'] as num).toInt(),
      status: json['status'] as String,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$DriverProfileToJson(_DriverProfile instance) =>
    <String, dynamic>{
      'id': const DriverIdConverter().toJson(instance.id),
      'vehicle_plate': instance.vehiclePlate,
      'capacity_kg': instance.capacityKg,
      'status': instance.status,
      'active': instance.active,
    };
