import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class TokenStore {
  TokenStore(this._storage);

  static const String _kSession = 'driver_session';
  static const List<String> _legacyKeys = <String>[
    'driver_token',
    'driver_refresh_token',
    'driver_id',
    'expires_at',
  ];

  static const String _fToken = 'token';
  static const String _fRefreshToken = 'refresh_token';
  static const String _fDriverId = 'driver_id';
  static const String _fExpiresAt = 'expires_at';

  final FlutterSecureStorage _storage;

  Future<void> save(DriverSession session, DateTime expiresAt) async {
    await _storage.write(
      key: _kSession,
      value: jsonEncode(<String, Object>{
        _fToken: session.token,
        _fRefreshToken: session.refreshToken,
        _fDriverId: session.driverId.value,
        _fExpiresAt: expiresAt.toUtc().toIso8601String(),
      }),
    );
  }

  Future<DriverSession?> read() async {
    final Map<String, Object?>? record = await _record();

    if (record == null) {
      return null;
    }

    final Object? token = record[_fToken];
    final Object? refreshToken = record[_fRefreshToken];
    final Object? driverId = record[_fDriverId];

    if (token is! String ||
        refreshToken is! String ||
        driverId is! int ||
        _expiresAt(record) == null) {
      return null;
    }

    return new DriverSession(
      driverId: new DriverId(driverId),
      token: token,
      refreshToken: refreshToken,
    );
  }

  Future<bool> accessExpired() async {
    final Map<String, Object?>? record = await _record();
    final DateTime? expiresAt = record == null ? null : _expiresAt(record);

    return expiresAt == null || !clock.now().toUtc().isBefore(expiresAt);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kSession);

    for (final String key in _legacyKeys) {
      await _storage.delete(key: key);
    }
  }

  Future<Map<String, Object?>?> _record() async {
    final String? raw = await _storage.read(key: _kSession);

    if (raw == null) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(raw);

      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  DateTime? _expiresAt(Map<String, Object?> record) {
    final Object? value = record[_fExpiresAt];

    return value is String ? DateTime.tryParse(value) : null;
  }
}
