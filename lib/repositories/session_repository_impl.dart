import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._api, this._store);

  final DriverApi _api;
  final TokenStore _store;

  @override
  Future<DriverSession?> currentSession() => _store.read();

  @override
  Future<Result<DriverSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final SessionResponse auth = await _api.login(
        new LoginRequest(email: email, password: password),
      );

      final DriverProfileEnvelope profile = await _api.me(
        _bearer(auth.accessToken),
      );

      return await _remember(
        new DriverSession(
          driverId: profile.data.id,
          token: auth.accessToken,
          refreshToken: auth.refreshToken,
        ),
        auth.expiresIn,
      );
    } on DioException catch (e) {
      return new Err<DriverSession>(_mapDio(e));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }
  }

  @override
  Future<Result<DriverSession>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehiclePlate,
    required int capacityKg,
  }) async {
    try {
      final CourierRegistrationResponse registered = await _api.registerCourier(
        new RegisterCourierRequest(
          email: email,
          password: password,
          fullName: name,
          phoneNumber: phone,
          vehiclePlate: vehiclePlate,
          capacityKg: capacityKg,
        ),
      );

      return await _remember(
        new DriverSession(
          driverId: registered.driverId,
          token: registered.accessToken,
          refreshToken: registered.refreshToken,
        ),
        registered.expiresIn,
      );
    } on DioException catch (e) {
      return new Err<DriverSession>(_mapDio(e));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }
  }

  Future<Result<DriverSession>> _remember(
    DriverSession session,
    int expiresIn,
  ) async {
    await _store.save(
      session,
      clock.now().toUtc().add(new Duration(seconds: expiresIn)),
    );

    return new Ok<DriverSession>(session);
  }

  String _bearer(String token) => 'Bearer $token';

  Failure _mapDio(DioException e) {
    AppLogger.debug('auth failed: HTTP ${e.response?.statusCode}');
    final Object? responseData = e.response?.data;
    final Map<String, dynamic>? dataMap = responseData is Map<String, dynamic>
        ? responseData
        : null;

    return switch (e.response?.statusCode) {
      401 => const AuthFailure('invalid email or password'),
      403 => const PendingApprovalFailure(),
      404 => const RegistrationIncompleteFailure(),
      409 => new AuthFailure(
        dataMap?['message']?.toString() ??
            'an account with that email already exists',
      ),
      400 => new ChannelFailure(
        dataMap?['message']?.toString() ?? 'check the details and try again',
      ),
      422 => new ChannelFailure(
        dataMap != null && dataMap['errors'] != null
            ? dataMap['errors'].toString()
            : 'registration validation failed',
      ),
      503 => new ChannelFailure(
        dataMap?['message']?.toString() ??
            'the fleet could not be reached; submit the same details again to finish',
      ),
      _ => const NetworkFailure(),
    };
  }

  @override
  Future<void> logout() => _store.clear();
}
