import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:kinetix_courier/config/app_config.dart';
import 'package:kinetix_courier/services/auth/driver_api.dart';
import 'package:kinetix_courier/services/seal/seal_api.dart';

@module
abstract class RegisterModule {
  @lazySingleton
  Dio get dio => new Dio(
    new BaseOptions(
      baseUrl: AppConfig.httpBase,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: const <String, String>{'Content-Type': 'application/json'},
    ),
  );

  @lazySingleton
  @Named('storage')
  Dio get storageDio => new Dio(
    new BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  @lazySingleton
  DriverApi driverApi(Dio dio) => new DriverApi(dio);

  @lazySingleton
  SealApi sealApi(Dio dio) => new SealApi(dio);

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}
