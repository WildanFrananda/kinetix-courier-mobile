import 'dart:io' show HttpStatus;

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._api, this._store, this._renewer, this._fleet);

  static const Duration _logoutTimeout = Duration(seconds: 5);
  static const String _tooManyAttempts =
      'Too many attempts. Wait a minute, then try again.';
  static const String _unreadable =
      'Identity answered in a way this app cannot read. Try again shortly.';

  final DriverApi _api;
  final TokenStore _store;
  final SessionRenewer _renewer;
  final FleetStanding _fleet;

  @override
  Future<DriverSession?> currentSession() async {
    final DriverSession? stored = await _store.read();

    if (stored == null || !await _store.accessExpired()) {
      return stored;
    }

    return switch (await _renewer.renew()) {
      Ok<DriverSession>(:final DriverSession value) => value,
      Err<DriverSession>(:final Failure failure) =>
        failure is AuthFailure ? null : stored,
    };
  }

  @override
  Future<Result<DriverProfile>> standing() async {
    final DriverSession? stored = await _store.read();

    if (stored == null) {
      return const Err<DriverProfile>(AuthFailure());
    }

    final Result<DriverProfile> standing = await _fleet.check(stored.token);

    if (standing case Err<DriverProfile>(failure: AuthFailure())) {
      return switch (await _renewer.renew()) {
        Ok<DriverSession>(:final DriverSession value) => await _fleet.check(
          value.token,
        ),
        Err<DriverSession>(:final Failure failure) => new Err<DriverProfile>(
          failure,
        ),
      };
    }

    return standing;
  }

  @override
  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
  }) async {
    final Object? raw;

    try {
      raw = await _api.login(
        new LoginRequest(email: email, password: password),
      );
    } on DioException catch (e) {
      return new Err<LoginOutcome>(_signInRefusal(e.response));
    } on Object {
      return const Err<LoginOutcome>(NetworkFailure());
    }

    if (raw is! Map<String, dynamic>) {
      return const Err<LoginOutcome>(ServiceUnavailableFailure(_unreadable));
    }

    final Map<String, dynamic> answer = raw;

    if (answer['mfaRequired'] == true) {
      final TwoFactorChallenge? challenge = _parsed(
        () => TwoFactorChallenge.fromJson(answer),
      );

      return challenge == null
          ? const Err<LoginOutcome>(ServiceUnavailableFailure(_unreadable))
          : new Ok<LoginOutcome>(new SecondFactorRequired(challenge));
    }

    final SessionResponse? auth = _parsed(
      () => SessionResponse.fromJson(answer),
    );

    if (auth == null) {
      return const Err<LoginOutcome>(ServiceUnavailableFailure(_unreadable));
    }

    return switch (await _admit(auth)) {
      Ok<DriverSession>(:final DriverSession value) => new Ok<LoginOutcome>(
        new LoggedIn(value),
      ),
      Err<DriverSession>(:final Failure failure) => new Err<LoginOutcome>(
        failure,
      ),
    };
  }

  @override
  Future<Result<DriverSession>> verifySecondFactor({
    required TwoFactorChallenge challenge,
    required String code,
  }) async {
    final SessionResponse auth;

    try {
      auth = await _api.verifyTwoFactor(
        new TwoFactorVerifyRequest(
          challengeToken: challenge.challengeToken,
          code: code,
        ),
      );
    } on DioException catch (e) {
      return new Err<DriverSession>(_secondFactorRefusal(e.response));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }

    return _admit(auth);
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
      return new Err<DriverSession>(_registrationRefusal(e.response));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }
  }

  @override
  Future<void> logout() async {
    final DriverSession? stored = await _store.read();

    if (stored != null) {
      await _revoke(stored);
    }

    await _store.clear();
  }

  Future<void> _revoke(DriverSession session) async {
    try {
      await _tellIdentity(session);
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;

      if (status != HttpStatus.unauthorized) {
        AppLogger.debug('logout not confirmed by identity: HTTP $status');

        return;
      }

      await _revokeRenewed();
    } on Object catch (e) {
      AppLogger.debug('logout not confirmed by identity: $e');
    }
  }

  Future<void> _revokeRenewed() async {
    final Result<DriverSession> renewed = await _renewer.renew();

    if (renewed case Ok<DriverSession>(:final DriverSession value)) {
      try {
        await _tellIdentity(value);
      } on Object catch (e) {
        AppLogger.debug('logout not confirmed by identity: $e');
      }
    }
  }

  Future<void> _tellIdentity(DriverSession session) {
    return _api
        .logout(
          _bearer(session.token),
          new LogoutRequest(refreshToken: session.refreshToken),
        )
        .timeout(_logoutTimeout);
  }

  Future<Result<DriverSession>> _admit(SessionResponse auth) async {
    return switch (await _fleet.check(auth.accessToken)) {
      Ok<DriverProfile>(:final DriverProfile value) => await _remember(
        new DriverSession(
          driverId: value.id,
          token: auth.accessToken,
          refreshToken: auth.refreshToken,
        ),
        auth.expiresIn,
      ),
      Err<DriverProfile>(:final Failure failure) => new Err<DriverSession>(
        failure,
      ),
    };
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

  T? _parsed<T>(T Function() parse) {
    try {
      return parse();
    } on Object catch (e) {
      AppLogger.error(
        'identity answered a shape this app cannot read',
        error: e,
      );

      return null;
    }
  }

  Failure _signInRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('sign-in refused: HTTP ${response?.statusCode}');

    return switch (response?.statusCode) {
      null => const NetworkFailure(),
      HttpStatus.unauthorized => const AuthFailure(
        'The email or password is not correct.',
      ),
      HttpStatus.badRequest => new RefusedFailure(
        said ?? 'Check the email and password.',
      ),
      HttpStatus.tooManyRequests => const RefusedFailure(_tooManyAttempts),
      _ => const ServiceUnavailableFailure(
        'Signing in is not available right now. Try again shortly.',
      ),
    };
  }

  Failure _secondFactorRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('second factor refused: HTTP ${response?.statusCode}');

    return switch (response?.statusCode) {
      null => const NetworkFailure(),
      HttpStatus.unauthorized => new RefusedFailure(
        said ?? 'That code was not accepted.',
      ),
      HttpStatus.badRequest => new RefusedFailure(
        said ?? 'Enter the six-digit code from your authenticator app.',
      ),
      HttpStatus.tooManyRequests => const RefusedFailure(_tooManyAttempts),
      _ => const ServiceUnavailableFailure(
        'The code could not be checked right now. Try again shortly.',
      ),
    };
  }

  Failure _registrationRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('registration refused: HTTP ${response?.statusCode}');

    return switch (response?.statusCode) {
      null => const NetworkFailure(),
      HttpStatus.badRequest || HttpStatus.conflict => new RefusedFailure(
        said ?? 'Check the details and submit again.',
      ),
      HttpStatus.tooManyRequests => const RefusedFailure(_tooManyAttempts),
      HttpStatus.serviceUnavailable => new ServiceUnavailableFailure(
        said ??
            'Registration did not finish. Submit the same details again; '
                'nothing will be duplicated.',
      ),
      _ => const ServiceUnavailableFailure(
        'Registration did not finish. Submit the same details again; '
        'nothing will be duplicated.',
      ),
    };
  }

  String? _messageOf(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final Object? message = body['message'];

    if (message is String && message.isNotEmpty) {
      return message;
    }

    if (message is List<dynamic>) {
      final List<String> lines = message.whereType<String>().toList();

      return lines.isEmpty ? null : lines.join('\n');
    }

    return null;
  }
}
