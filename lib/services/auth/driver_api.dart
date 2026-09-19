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
  Future<SessionResponse> login(@Body() LoginRequest body);

  @GET('${AppConfig.matchingPath}/driver/me')
  Future<DriverProfileEnvelope> me(
    @Header('Authorization') String authorization,
  );
}
