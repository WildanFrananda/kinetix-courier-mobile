import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/models/delivery_proof_draft.dart';
import 'package:fleet_pulse_mobile/models/ids.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

typedef ProofDraftBoxOpener = Future<Box<Map<dynamic, dynamic>>> Function();

@lazySingleton
class ProofDraftStore {
  ProofDraftStore() : _open = _openOnDevice;

  @visibleForTesting
  ProofDraftStore.withOpener(this._open);

  static const String boxName = 'delivery_proof_drafts';
  static const Duration maxAge = Duration(hours: 24);

  static const String _fPhotoUrl = 'photo_url';
  static const String _fSignature = 'signature';
  static const String _fSavedAt = 'saved_at';

  final ProofDraftBoxOpener _open;

  Future<Box<Map<dynamic, dynamic>>>? _box;

  static Future<Box<Map<dynamic, dynamic>>> _openOnDevice() async {
    await Hive.initFlutter();

    return Hive.openBox<Map<dynamic, dynamic>>(boxName);
  }

  Future<DeliveryProofDraft> read(DriverId driver, OrderId order) async {
    final Box<Map<dynamic, dynamic>> box = await _opened();
    final String key = _keyOf(driver, order);
    final Map<dynamic, dynamic>? raw = box.get(key);

    if (raw == null) {
      return const DeliveryProofDraft();
    }

    final Object? savedAt = raw[_fSavedAt];
    final DateTime? at = savedAt is String ? DateTime.tryParse(savedAt) : null;

    if (at == null || clock.now().toUtc().difference(at) > maxAge) {
      await box.delete(key);

      return const DeliveryProofDraft();
    }

    final Object? photoUrl = raw[_fPhotoUrl];
    final Object? signature = raw[_fSignature];

    return new DeliveryProofDraft(
      photoUrl: photoUrl is String ? photoUrl : null,
      signature: signature is String ? signature : null,
    );
  }

  Future<void> keepPhoto(DriverId driver, OrderId order, String photoUrl) {
    return _merge(driver, order, _fPhotoUrl, photoUrl);
  }

  Future<void> keepSignature(DriverId driver, OrderId order, String signature) {
    return _merge(driver, order, _fSignature, signature);
  }

  Future<void> forget(DriverId driver, OrderId order) async {
    final Box<Map<dynamic, dynamic>> box = await _opened();

    await box.delete(_keyOf(driver, order));
  }

  Future<void> _merge(
    DriverId driver,
    OrderId order,
    String field,
    String value,
  ) async {
    final Box<Map<dynamic, dynamic>> box = await _opened();
    final String key = _keyOf(driver, order);

    await box.put(key, <dynamic, dynamic>{
      ...?box.get(key),
      field: value,
      _fSavedAt: clock.now().toUtc().toIso8601String(),
    });
  }

  Future<Box<Map<dynamic, dynamic>>> _opened() async {
    final Future<Box<Map<dynamic, dynamic>>>? opening = _box;

    if (opening != null) {
      return opening;
    }

    final Future<Box<Map<dynamic, dynamic>>> fresh = _open();

    _box = fresh;

    try {
      return await fresh;
    } on Object {
      _box = null;
      rethrow;
    }
  }

  String _keyOf(DriverId driver, OrderId order) {
    return '${driver.value}:${order.value}';
  }
}
