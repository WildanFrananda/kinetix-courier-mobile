import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
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
  static const String _ownerSeparator = ':';

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

  Future<void> add(DriverId owner, TelemetryPing ping) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();

    await box.put(_keyOf(owner, ping.recordedAt), _encode(ping));

    final int excess = box.length - capacity;

    if (excess > 0) {
      await box.deleteAll(
        _oldestFirst(box.keys.whereType<String>()).take(excess),
      );
    }
  }

  Future<List<TelemetryPing>> oldest(DriverId owner, int limit) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();
    final List<TelemetryPing> pings = <TelemetryPing>[];

    for (final String key in _keysOf(box, owner).take(limit)) {
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

  Future<void> remove(DriverId owner, Iterable<TelemetryPing> pings) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();

    await box.deleteAll(<String>[
      for (final TelemetryPing ping in pings) _keyOf(owner, ping.recordedAt),
    ]);
  }

  Future<int> discardRecordedBefore(DateTime cutoff) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _opened();
    final String limit = _moment(cutoff);
    final List<String> stale = <String>[
      for (final String key in box.keys.whereType<String>())
        if ((_momentOf(key) ?? '').compareTo(limit) < 0) key,
    ];

    await box.deleteAll(stale);

    return stale.length;
  }

  Future<LazyBox<Map<dynamic, dynamic>>> _opened() async {
    final Future<LazyBox<Map<dynamic, dynamic>>>? opening = _box;

    if (opening != null) {
      return opening;
    }

    final Future<LazyBox<Map<dynamic, dynamic>>> fresh = _open().then(
      _withoutOrphans,
    );

    _box = fresh;

    try {
      return await fresh;
    } on Object {
      _box = null;
      rethrow;
    }
  }

  Future<LazyBox<Map<dynamic, dynamic>>> _withoutOrphans(
    LazyBox<Map<dynamic, dynamic>> box,
  ) async {
    final List<dynamic> orphans = <dynamic>[
      for (final dynamic key in box.keys)
        if (key is! String || _momentOf(key) == null) key,
    ];

    if (orphans.isNotEmpty) {
      AppLogger.error(
        'dropped ${orphans.length} offline positions kept without a courier',
      );
      await box.deleteAll(orphans);
    }

    return box;
  }

  List<String> _keysOf(LazyBox<Map<dynamic, dynamic>> box, DriverId owner) {
    final String prefix = '${owner.value}$_ownerSeparator';

    return box.keys
        .whereType<String>()
        .where((String key) => key.startsWith(prefix))
        .toList()
      ..sort();
  }

  List<String> _oldestFirst(Iterable<String> keys) {
    return keys.toList()..sort(
      (String a, String b) =>
          (_momentOf(a) ?? '').compareTo(_momentOf(b) ?? ''),
    );
  }

  String _keyOf(DriverId owner, DateTime at) {
    return '${owner.value}$_ownerSeparator${_moment(at)}';
  }

  String _moment(DateTime at) {
    return at.toUtc().microsecondsSinceEpoch.toString().padLeft(
      _keyDigits,
      '0',
    );
  }

  String? _momentOf(String key) {
    final int separator = key.indexOf(_ownerSeparator);

    if (separator <= 0 || int.tryParse(key.substring(0, separator)) == null) {
      return null;
    }

    final String moment = key.substring(separator + 1);

    return moment.length == _keyDigits && int.tryParse(moment) != null
        ? moment
        : null;
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
