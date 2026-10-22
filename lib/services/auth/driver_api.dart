import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:retrofit/retrofit.dart';

part 'driver_api.g.dart';

@RestApi()
abstract class DriverApi {
  factory DriverApi(Dio dio, {String baseUrl}) = _DriverApi;

  @POST('${AppConfig.couriersPath}/register')
  Future<CourierRegistrationResponse> registerCourier(
    @Body() RegisterCourierRequest body,
  );

  @POST('${AppConfig.authPath}/login')
  Future<dynamic> login(@Body() LoginRequest body);

  @POST('${AppConfig.authPath}/2fa/verify')
  Future<SessionResponse> verifyTwoFactor(@Body() TwoFactorVerifyRequest body);

  @POST('${AppConfig.authPath}/refresh')
  Future<SessionResponse> refresh(@Body() RefreshRequest body);

  @POST('${AppConfig.authPath}/logout')
  Future<void> logout(
    @Header('Authorization') String authorization,
    @Body() LogoutRequest body,
  );

  @GET('${AppConfig.matchingPath}/driver/me')
  Future<DriverProfileEnvelope> me(
    @Header('Authorization') String authorization,
  );
}
