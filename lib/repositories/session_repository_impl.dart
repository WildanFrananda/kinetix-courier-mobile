import 'dart:io' show HttpStatus;

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_unavailable_exception.dart';
import 'package:fleet_pulse_mobile/services/auth/answer_parser.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:fleet_pulse_mobile/services/auth/identity_error.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(
    this._api,
    this._store,
    this._renewer,
    this._fleet,
    this._proof,
  );

  static const Duration _logoutTimeout = Duration(seconds: 5);
  static const String _tooManyAttempts =
      'Too many attempts. Wait a minute, then try again.';
  static const String _unreadable =
      'Identity answered in a way this app cannot read. Try again shortly.';
  static const String _unreadableSession =
      'Identity accepted the sign-in, but its answer could not be read. Sign '
      'in again.';
  static const String _unreadableRegistration =
      'Registration finished, but its answer could not be read. Go back and '
      'sign in with the same email and password.';
  static const String _noProof =
      'This phone could not prove the app is genuine just now. Check the '
      'connection and try again.';
  static const String _proofUnverifiable =
      'Identity could not check this app just now. Try again shortly.';
  static const String _challengeExhausted =
      'Too many wrong codes for this sign-in. Enter your password again, then '
      'the current code.';
  static const String _challengeSpent =
      'This sign-in can no longer be completed. Enter your password again.';

  final DriverApi _api;
  final TokenStore _store;
  final SessionRenewer _renewer;
  final FleetStanding _fleet;
  final ClientProof _proof;

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
        Ok<DriverSession>(:final DriverSession value) => await _bound(
          value,
          await _fleet.check(value.token),
        ),
        Err<DriverSession>(:final Failure failure) => new Err<DriverProfile>(
          failure,
        ),
      };
    }

    return _bound(stored, standing);
  }

  @override
  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
  }) async {
    final Object? raw;

    try {
      raw = await _proof.present(
        (String proof) => _api.login(
          proof,
          new LoginRequest(email: email, password: password),
        ),
      );
    } on ClientProofUnavailableException {
      return const Err<LoginOutcome>(ServiceUnavailableFailure(_noProof));
    } on DioException catch (e) {
      return new Err<LoginOutcome>(_signInRefusal(e.response));
    } on Object {
      return const Err<LoginOutcome>(NetworkFailure());
    }

    if (raw is Map<String, dynamic> && raw['mfaEnrolmentRequired'] == true) {
      AppLogger.debug('an administrator signed in; this app keeps nothing');

      return const Err<LoginOutcome>(AdminAccountFailure());
    }

    if (raw is Map<String, dynamic> && raw['mfaRequired'] == true) {
      final TwoFactorChallenge? challenge = AnswerParser.parse(
        raw,
        TwoFactorChallenge.fromJson,
        from: 'identity',
      );

      return challenge == null
          ? const Err<LoginOutcome>(UnreadableAnswerFailure(_unreadable))
          : new Ok<LoginOutcome>(new SecondFactorRequired(challenge));
    }

    final SessionResponse? auth = AnswerParser.parse(
      raw,
      SessionResponse.fromJson,
      from: 'identity',
    );

    if (auth == null) {
      return const Err<LoginOutcome>(UnreadableAnswerFailure(_unreadable));
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
    final Object? raw;

    try {
      raw = await _proof.present(
        (String proof) => _api.verifyTwoFactor(
          proof,
          new TwoFactorVerifyRequest(
            challengeToken: challenge.challengeToken,
            code: code,
          ),
        ),
      );
    } on ClientProofUnavailableException {
      return const Err<DriverSession>(ServiceUnavailableFailure(_noProof));
    } on DioException catch (e) {
      return new Err<DriverSession>(_secondFactorRefusal(e.response));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }

    final SessionResponse? auth = AnswerParser.parse(
      raw,
      SessionResponse.fromJson,
      from: 'identity',
    );

    if (auth == null) {
      return const Err<DriverSession>(
        UnreadableAnswerFailure(_unreadableSession),
      );
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
    final Object? raw;

    try {
      raw = await _proof.present(
        (String proof) => _api.registerCourier(
          proof,
          new RegisterCourierRequest(
            email: email,
            password: password,
            fullName: name,
            phoneNumber: phone,
            vehiclePlate: vehiclePlate,
            capacityKg: capacityKg,
          ),
        ),
      );
    } on ClientProofUnavailableException {
      return const Err<DriverSession>(ServiceUnavailableFailure(_noProof));
    } on DioException catch (e) {
      return new Err<DriverSession>(_registrationRefusal(e.response));
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }

    final CourierRegistrationResponse? registered = AnswerParser.parse(
      raw,
      CourierRegistrationResponse.fromJson,
      from: 'identity',
    );

    if (registered == null) {
      return const Err<DriverSession>(
        UnreadableAnswerFailure(_unreadableRegistration),
      );
    }

    return _remember(
      new DriverSession(
        driverId: registered.driverId,
        token: registered.accessToken,
        refreshToken: registered.refreshToken,
      ),
      registered.expiresIn,
    );
  }

  @override
  Future<void> logout() async {
    final DriverSession? stored = await _store.read();

    if (stored != null) {
      await _revoke(stored);
    }

    await _store.clear();
  }

  Future<Result<DriverProfile>> _bound(
    DriverSession session,
    Result<DriverProfile> standing,
  ) async {
    if (standing case Ok<DriverProfile>(
      :final DriverProfile value,
    ) when value.id != session.driverId) {
      AppLogger.debug('the fleet names this courier driver ${value.id.value}');
      await _store.rebind(value.id);
    }

    return standing;
  }

  Future<void> _revoke(DriverSession session) async {
    try {
      await _tellIdentity(session.token, session.refreshToken);
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
        await _tellIdentity(value.token, value.refreshToken);
      } on Object catch (e) {
        AppLogger.debug('logout not confirmed by identity: $e');
      }
    }
  }

  Future<void> _tellIdentity(String accessToken, String refreshToken) {
    return _api
        .logout(
          _bearer(accessToken),
          new LogoutRequest(refreshToken: refreshToken),
        )
        .timeout(_logoutTimeout);
  }

  Future<Result<DriverSession>> _admit(SessionResponse auth) async {
    final Result<DriverProfile> standing = await _fleet.check(auth.accessToken);

    switch (standing) {
      case Ok<DriverProfile>(:final DriverProfile value):
        return _remember(
          new DriverSession(
            driverId: value.id,
            token: auth.accessToken,
            refreshToken: auth.refreshToken,
          ),
          auth.expiresIn,
        );
      case Err<DriverProfile>(:final Failure failure)
          when failure is PendingApprovalFailure:
        await _remember(
          new DriverSession(
            driverId: null,
            token: auth.accessToken,
            refreshToken: auth.refreshToken,
          ),
          auth.expiresIn,
        );

        return new Err<DriverSession>(failure);
      case Err<DriverProfile>(:final Failure failure):
        await _abandon(auth);

        return new Err<DriverSession>(failure);
    }
  }

  Future<void> _abandon(SessionResponse auth) async {
    try {
      await _tellIdentity(auth.accessToken, auth.refreshToken);
    } on Object catch (e) {
      AppLogger.debug('a session the fleet did not admit was not revoked: $e');
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

  Failure? _clientRefusal(Response<dynamic>? response) {
    if (IdentityError.proofUnverifiable(response)) {
      return const ServiceUnavailableFailure(_proofUnverifiable);
    }

    if (IdentityError.refusesProof(response)) {
      return const UntrustedClientFailure();
    }

    if (IdentityError.outdatedClient(response)) {
      return const AppUpdateRequiredFailure();
    }

    return null;
  }

  Failure _delayed(Response<dynamic>? response) {
    final Duration? wait = IdentityError.delayOf(response);

    return wait == null
        ? const RefusedFailure(_tooManyAttempts)
        : new SignInDelayedFailure(wait);
  }

  Failure _codeRefused(Response<dynamic>? response) {
    if (IdentityError.wrongCode(response)) {
      return const RefusedFailure(IdentityError.wrongCodeMessage);
    }

    if (IdentityError.challengeExhausted(response)) {
      return const ChallengeSpentFailure(_challengeExhausted);
    }

    return const ChallengeSpentFailure(_challengeSpent);
  }

  Failure _signInRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('sign-in refused: HTTP ${response?.statusCode}');

    return _clientRefusal(response) ??
        switch (response?.statusCode) {
          null => const NetworkFailure(),
          HttpStatus.unauthorized => const AuthFailure(
            'The email or password is not correct.',
          ),
          HttpStatus.badRequest => new RefusedFailure(
            said ?? 'Check the email and password.',
          ),
          HttpStatus.tooManyRequests => _delayed(response),
          _ => const ServiceUnavailableFailure(
            'Signing in is not available right now. Try again shortly.',
          ),
        };
  }

  Failure _secondFactorRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('second factor refused: HTTP ${response?.statusCode}');

    return _clientRefusal(response) ??
        switch (response?.statusCode) {
          null => const NetworkFailure(),
          HttpStatus.unauthorized => _codeRefused(response),
          HttpStatus.badRequest => new RefusedFailure(
            said ?? 'Enter the six-digit code from your authenticator app.',
          ),
          HttpStatus.tooManyRequests => _delayed(response),
          _ => const ServiceUnavailableFailure(
            'The code could not be checked right now. Try again shortly.',
          ),
        };
  }

  Failure _registrationRefusal(Response<dynamic>? response) {
    final String? said = _messageOf(response?.data);

    AppLogger.debug('registration refused: HTTP ${response?.statusCode}');

    return _clientRefusal(response) ??
        switch (response?.statusCode) {
          null => const NetworkFailure(),
          HttpStatus.badRequest || HttpStatus.conflict => new RefusedFailure(
            said ?? 'Check the details and submit again.',
          ),
          HttpStatus.tooManyRequests => _delayed(response),
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
