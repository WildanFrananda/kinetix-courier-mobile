import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kinetix_courier/models/driver_profile.dart';

part 'driver_profile_envelope.freezed.dart';
part 'driver_profile_envelope.g.dart';

@freezed
abstract class DriverProfileEnvelope with _$DriverProfileEnvelope {
  const factory DriverProfileEnvelope({required DriverProfile data}) =
      _DriverProfileEnvelope;

  factory DriverProfileEnvelope.fromJson(Map<String, dynamic> json) =>
      _$DriverProfileEnvelopeFromJson(json);
}
