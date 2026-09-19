import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TokenStore {
  TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _kToken = 'driver_token';
  static const String _kRefreshToken = 'driver_refresh_token';
  static const String _kDriverId = 'driver_id';
  static const String _kExpiresAt = 'expires_at';

  Future<void> save(DriverSession session, DateTime expiresAt) async {
    await _storage.write(key: _kToken, value: session.token);
    await _storage.write(key: _kRefreshToken, value: session.refreshToken);
    await _storage.write(
      key: _kDriverId,
      value: session.driverId.value.toString(),
    );
    await _storage.write(
      key: _kExpiresAt,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<DriverSession?> read() async {
    final String? token = await _storage.read(key: _kToken);
    final String? refreshToken = await _storage.read(key: _kRefreshToken);
    final String? id = await _storage.read(key: _kDriverId);
    final String? expiresAtStr = await _storage.read(key: _kExpiresAt);

    if (token == null || refreshToken == null || id == null || expiresAtStr == null) {
      return null;
    }

    final int? parsed = int.tryParse(id);
    final DateTime? expiresAt = DateTime.tryParse(expiresAtStr);

    if (parsed == null || expiresAt == null) {
      return null;
    }

    if (!clock.now().toUtc().isBefore(expiresAt)) {
      await clear();

      return null;
    }

    return new DriverSession(
      driverId: new DriverId(parsed),
      token: token,
      refreshToken: refreshToken,
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kDriverId);
    await _storage.delete(key: _kExpiresAt);
  }
}
