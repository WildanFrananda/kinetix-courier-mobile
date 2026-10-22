import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

typedef PositionBoxOpener = Future<LazyBox<Map<dynamic, dynamic>>> Function();

@lazySingleton
class OfflinePositionStore {
  OfflinePositionStore() : _open = _openOnDevice, capacity = defaultCapacity;

  @visibleForTesting
  OfflinePositionStore.withOpener(
    this._open, {
    this.capacity = defaultCapacity,
  });

  static const String boxName = 'offline_positions';
  static const int defaultCapacity = 21600;
  static const int _keyDigits = 17;

  static const String _fLatitude = 'latitude';
  static const String _fLongitude = 'longitude';
  static const String _fRecordedAt = 'recorded_at';
  static const String _fSpeedKmh = 'speed_kmh';
  static const String _fBearingDeg = 'bearing_deg';

  final PositionBoxOpener _open;
  final int capacity;

  Future<LazyBox<Map<dynamic, dynamic>>>? _box;

  static Future<LazyBox<Map<dynamic, dynamic>>> _openOnDevice() async {
    await Hive.initFlutter();

    return Hive.openLazyBox<Map<dynamic, dynamic>>(boxName);
  }

  Future<int> count() async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();

    return box.length;
  }

  Future<void> add(TelemetryPing ping) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();

    await box.put(_keyOf(ping.recordedAt), _encode(ping));

    final int excess = box.length - capacity;

    if (excess > 0) {
      await box.deleteAll(_sortedKeys(box).take(excess));
    }
  }

  Future<List<TelemetryPing>> oldest(int limit) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();
    final List<TelemetryPing> pings = <TelemetryPing>[];

    for (final String key in _sortedKeys(box).take(limit)) {
      final Map<dynamic, dynamic>? raw = await box.get(key);
      final TelemetryPing? ping = raw == null ? null : _decode(raw);

      if (ping == null) {
        await box.delete(key);
      } else {
        pings.add(ping);
      }
    }

    return pings;
  }

  Future<void> remove(Iterable<TelemetryPing> pings) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();

    await box.deleteAll(<String>[
      for (final TelemetryPing ping in pings) _keyOf(ping.recordedAt),
    ]);
  }

  Future<int> discardRecordedBefore(DateTime cutoff) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();
    final String limit = _keyOf(cutoff);
    final List<String> stale = _sortedKeys(
      box,
    ).takeWhile((String key) => key.compareTo(limit) < 0).toList();

    await box.deleteAll(stale);

    return stale.length;
  }

  Future<LazyBox<Map<dynamic, dynamic>>> _opened() async {
    final Future<LazyBox<Map<dynamic, dynamic>>>? opening = _box;

    if (opening != null) {
      return opening;
    }

    final Future<LazyBox<Map<dynamic, dynamic>>> fresh = _open();

    _box = fresh;

    try {
      return await fresh;
    } on Object {
      _box = null;
      rethrow;
    }
  }

  List<String> _sortedKeys(LazyBox<Map<dynamic, dynamic>> box) {
    return box.keys.whereType<String>().toList()..sort();
  }

  String _keyOf(DateTime at) {
    return at.toUtc().microsecondsSinceEpoch.toString().padLeft(
      _keyDigits,
      '0',
    );
  }

  Map<String, Object?> _encode(TelemetryPing ping) {
    return <String, Object?>{
      _fLatitude: ping.latitude,
      _fLongitude: ping.longitude,
      _fRecordedAt: ping.recordedAt.toUtc().toIso8601String(),
      _fSpeedKmh: ping.speedKmh,
      _fBearingDeg: ping.bearingDeg,
    };
  }

  TelemetryPing? _decode(Map<dynamic, dynamic> raw) {
    final Object? latitude = raw[_fLatitude];
    final Object? longitude = raw[_fLongitude];
    final Object? recordedAt = raw[_fRecordedAt];
    final Object? speedKmh = raw[_fSpeedKmh];
    final Object? bearingDeg = raw[_fBearingDeg];
    final DateTime? at = recordedAt is String
        ? DateTime.tryParse(recordedAt)
        : null;

    if (latitude is! num || longitude is! num || at == null) {
      return null;
    }

    return new TelemetryPing(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      recordedAt: at.toUtc(),
      speedKmh: speedKmh is num ? speedKmh.toDouble() : null,
      bearingDeg: bearingDeg is num ? bearingDeg.toDouble() : null,
    );
  }
}
