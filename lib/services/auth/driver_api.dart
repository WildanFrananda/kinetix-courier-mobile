import 'package:dio/dio.dart' hide Headers;
import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:retrofit/retrofit.dart';

part 'driver_api.g.dart';

@RestApi()
abstract class DriverApi {
  factory DriverApi(Dio dio, {String baseUrl}) = _DriverApi;

  @POST('${AppConfig.couriersPath}/register')
  @Headers(<String, dynamic>{AppConfig.clientHeader: AppConfig.clientName})
  Future<dynamic> registerCourier(
    @Header(AppConfig.clientProofHeader) String proof,
    @Body() RegisterCourierRequest body,
  );

  @POST('${AppConfig.authPath}/login')
  @Headers(<String, dynamic>{AppConfig.clientHeader: AppConfig.clientName})
  Future<dynamic> login(
    @Header(AppConfig.clientProofHeader) String proof,
    @Body() LoginRequest body,
  );

  @POST('${AppConfig.authPath}/2fa/verify')
  @Headers(<String, dynamic>{AppConfig.clientHeader: AppConfig.clientName})
  Future<dynamic> verifyTwoFactor(
    @Header(AppConfig.clientProofHeader) String proof,
    @Body() TwoFactorVerifyRequest body,
  );

  @POST('${AppConfig.authPath}/refresh')
  @Headers(<String, dynamic>{AppConfig.clientHeader: AppConfig.clientName})
  Future<dynamic> refresh(
    @Header(AppConfig.clientProofHeader) String proof,
    @Body() RefreshRequest body,
  );

  @POST('${AppConfig.authPath}/logout')
  Future<void> logout(
    @Header('Authorization') String authorization,
    @Body() LogoutRequest body,
  );

  @GET('${AppConfig.matchingPath}/driver/me')
  Future<dynamic> me(@Header('Authorization') String authorization);
}
