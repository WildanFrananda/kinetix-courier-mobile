import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SessionRenewer {
  SessionRenewer(this._api, this._store);

  final DriverApi _api;
  final TokenStore _store;

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

    try {
      final SessionResponse auth = await _api.refresh(
        new RefreshRequest(refreshToken: stored.refreshToken),
      );
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
    } on DioException catch (e) {
      final int? code = e.response?.statusCode;

      if (code == 400 || code == 401) {
        AppLogger.debug('refresh refused: HTTP $code');
        await _store.clear();

        return const Err<DriverSession>(AuthFailure());
      }

      return const Err<DriverSession>(NetworkFailure());
    } on Object {
      return const Err<DriverSession>(NetworkFailure());
    }
  }
}
