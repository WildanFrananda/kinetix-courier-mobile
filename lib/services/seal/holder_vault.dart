import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class HolderVault {
  HolderVault(this._storage);

  static const String _secretKey = 'seal.holder_secret';

  static const String _credentialKey = 'seal.credential';

  static const String _snapshotKey = 'seal.snapshot';

  static const String _predicatesKey = 'seal.predicates';

  static const String _entryKey = 'seal.holder_entry';

  static const String _refreshedKey = 'seal.public_state_at';

  final FlutterSecureStorage _storage;

  Future<String> holderSecret() async {
    final String? stored = await _storage.read(key: _secretKey);

    if (stored != null) {
      return stored;
    }

    final Random random = Random.secure();
    final String secret = List<String>.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();

    await _storage.write(key: _secretKey, value: secret);

    return secret;
  }

  Future<String?> credential() {
    return _storage.read(key: _credentialKey);
  }

  Future<void> keepCredential(String json) {
    return _storage.write(key: _credentialKey, value: json);
  }

  Future<String?> snapshot() {
    return _storage.read(key: _snapshotKey);
  }

  Future<String?> predicates() {
    return _storage.read(key: _predicatesKey);
  }

  Future<String?> holderEntry() {
    return _storage.read(key: _entryKey);
  }

  Future<DateTime?> publicStateRefreshedAt() async {
    final String? stored = await _storage.read(key: _refreshedKey);

    return stored == null ? null : DateTime.tryParse(stored);
  }

  Future<void> keepPublicState({
    required String snapshot,
    required String predicates,
    required String holderEntry,
    required DateTime at,
  }) async {
    await _storage.write(key: _snapshotKey, value: snapshot);
    await _storage.write(key: _predicatesKey, value: predicates);
    await _storage.write(key: _entryKey, value: holderEntry);
    await _storage.write(
      key: _refreshedKey,
      value: at.toUtc().toIso8601String(),
    );
  }

  Future<void> forget() async {
    for (final String key in <String>[
      _secretKey,
      _credentialKey,
      _snapshotKey,
      _predicatesKey,
      _entryKey,
      _refreshedKey,
    ]) {
      await _storage.delete(key: key);
    }
  }
}
