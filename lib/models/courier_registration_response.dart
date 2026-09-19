import 'package:fleet_pulse_mobile/models/authenticated_account.dart';
import 'package:fleet_pulse_mobile/models/converters.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'courier_registration_response.freezed.dart';
part 'courier_registration_response.g.dart';

@freezed
abstract class CourierRegistrationResponse with _$CourierRegistrationResponse {
  const factory CourierRegistrationResponse({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required String tokenType,
    required AuthenticatedAccount user,
    @DriverIdConverter() required DriverId driverId,
  }) = _CourierRegistrationResponse;

  factory CourierRegistrationResponse.fromJson(Map<String, dynamic> json) =>
      _$CourierRegistrationResponseFromJson(json);
}
