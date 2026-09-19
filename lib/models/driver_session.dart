import 'package:fleet_pulse_mobile/models/converters.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_session.freezed.dart';
part 'driver_session.g.dart';

@freezed
abstract class DriverSession with _$DriverSession {
  const factory DriverSession({
    @JsonKey(name: 'driver_id') @DriverIdConverter() required DriverId driverId,
    required String token,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _DriverSession;

  factory DriverSession.fromJson(Map<String, dynamic> json) =>
      _$DriverSessionFromJson(json);
}
