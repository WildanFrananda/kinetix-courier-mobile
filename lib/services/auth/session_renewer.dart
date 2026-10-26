import 'dart:io' show HttpStatus;

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_unavailable_exception.dart';
import 'package:fleet_pulse_mobile/services/auth/answer_parser.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/identity_error.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionRenewer {
  SessionRenewer(this._api, this._store, this._proof);

  static const String _lost =
      'The connection dropped while the session was being renewed, so it '
      'cannot be renewed safely. Sign in again.';
  static const String _otherClient =
      'This session was started by another app, so this one cannot renew it. '
      'Sign in again.';

  final DriverApi _api;
  final TokenStore _store;
  final ClientProof _proof;

  Future<Result<DriverSession>>? _inFlight;

  Future<Result<DriverSession>> renew() {
    return _inFlight ??= _renew().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<Result<DriverSession>> _renew() async {
    final DriverSession? stored = await _store.read();

    if (stored == null) {
      return const Err<DriverSession>(AuthFailure());
    }

    final Object? raw;

    try {
      raw = await _proof.present(
        (String proof) => _api.refresh(
          proof,
          new RefreshRequest(refreshToken: stored.refreshToken),
        ),
      );
    } on ClientProofUnavailableException catch (e) {
      AppLogger.debug('refresh postponed, no client proof: $e');

      return const Err<DriverSession>(NetworkFailure());
    } on DioException catch (e) {
      return _unanswered(e);
    } on Object catch (e) {
      AppLogger.error('refresh could not be sent', error: e);

      return const Err<DriverSession>(NetworkFailure());
    }

    final SessionResponse? auth = AnswerParser.parse(
      raw,
      SessionResponse.fromJson,
      from: 'identity',
    );

    if (auth == null) {
      return _lose();
    }

    final DriverSession renewed = new DriverSession(
      driverId: stored.driverId,
      token: auth.accessToken,
      refreshToken: auth.refreshToken,
    );

    await _store.save(
      renewed,
      clock.now().toUtc().add(new Duration(seconds: auth.expiresIn)),
    );

    return new Ok<DriverSession>(renewed);
  }

  Future<Result<DriverSession>> _unanswered(DioException e) async {
    switch (e.type) {
      case DioExceptionType.connectionTimeout ||
          DioExceptionType.connectionError ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.badCertificate ||
          DioExceptionType.cancel:
        return const Err<DriverSession>(NetworkFailure());
      case DioExceptionType.receiveTimeout ||
          DioExceptionType.transformTimeout ||
          DioExceptionType.unknown:
        return _lose();
      case DioExceptionType.badResponse:
        return _answered(e.response);
    }
  }

  Future<Result<DriverSession>> _answered(Response<dynamic>? response) async {
    if (IdentityError.outdatedClient(response)) {
      AppLogger.error(
        'identity does not accept this build '
        '(${IdentityError.codeOf(response)}); the session is kept for an '
        'updated app',
      );

      return const Err<DriverSession>(AppUpdateRequiredFailure());
    }

    final int status = response?.statusCode ?? 0;
    if (status == HttpStatus.badRequest ||
        status == HttpStatus.unauthorized ||
        status == HttpStatus.forbidden) {
      AppLogger.debug(
        'refresh refused: HTTP $status ${IdentityError.codeOf(response)}',
      );
      await _store.clear();

      return new Err<DriverSession>(_refusal(response));
    }

    if (status >= HttpStatus.internalServerError &&
        status != HttpStatus.badGateway &&
        status != HttpStatus.serviceUnavailable) {
      return _lose();
    }

    AppLogger.debug('refresh not answered: HTTP $status');

    return const Err<DriverSession>(NetworkFailure());
  }

  AuthFailure _refusal(Response<dynamic>? response) {
    if (IdentityError.mismatchedClient(response)) {
      return const AuthFailure(_otherClient);
    }

    if (IdentityError.refusesProof(response)) {
      return new AuthFailure(const UntrustedClientFailure().message);
    }

    return const AuthFailure();
  }

  Future<Result<DriverSession>> _lose() async {
    AppLogger.error(
      'a refresh answer was lost; the refresh token may be spent, so it is '
      'never presented again',
    );
    await _store.clear();

    return const Err<DriverSession>(AuthFailure(_lost));
  }
}
