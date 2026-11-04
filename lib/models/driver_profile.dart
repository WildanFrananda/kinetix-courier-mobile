import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kinetix_courier/models/converters.dart';
import 'package:kinetix_courier/models/ids.dart';

part 'driver_profile.freezed.dart';
part 'driver_profile.g.dart';

@freezed
abstract class DriverProfile with _$DriverProfile {
  const factory DriverProfile({
    @DriverIdConverter() required DriverId id,
    @JsonKey(name: 'vehicle_plate') required String vehiclePlate,
    @JsonKey(name: 'capacity_kg') required int capacityKg,
    required String status,
    required bool active,
  }) = _DriverProfile;

  factory DriverProfile.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileFromJson(json);
}
