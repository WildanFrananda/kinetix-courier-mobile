import 'package:dio/dio.dart' hide Headers;
import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:retrofit/retrofit.dart';

part 'seal_api.g.dart';

@RestApi()
abstract class SealApi {
  factory SealApi(Dio dio, {String baseUrl}) = _SealApi;

  @POST('${AppConfig.sealPath}/courier-credentials')
  Future<dynamic> requestCredential(
    @Header('Authorization') String authorization,
    @Body() Map<String, dynamic> body,
  );

  @GET('${AppConfig.sealPath}/courier-credentials/{id}')
  Future<dynamic> credential(
    @Header('Authorization') String authorization,
    @Path('id') String id,
  );

  @GET('${AppConfig.sealPath}/registry/snapshot')
  Future<dynamic> snapshot();

  @GET('${AppConfig.sealPath}/predicates')
  Future<dynamic> predicates();

  @GET('${AppConfig.sealPath}/holder')
  Future<dynamic> holder();
}
