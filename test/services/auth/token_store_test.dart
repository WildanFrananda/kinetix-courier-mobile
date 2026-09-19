import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  late TokenStore sut;
  final DateTime fixedNow = DateTime.utc(2026, 1, 1);

  setUp(() {
    storage = new _MockStorage();
    sut = new TokenStore(storage);
  });

  void stubReads({
    String? token,
    String? refreshToken = 'refresh',
    String? id,
    String? expiresAt,
  }) {
    when(
      () => storage.read(key: 'driver_token'),
    ).thenAnswer((_) async => token);
    when(
      () => storage.read(key: 'driver_refresh_token'),
    ).thenAnswer((_) async => refreshToken);
    when(() => storage.read(key: 'driver_id')).thenAnswer((_) async => id);
    when(
      () => storage.read(key: 'expires_at'),
    ).thenAnswer((_) async => expiresAt);
  }

  test('read returns null when a key is missing', () async {
    stubReads(token: 'abc', id: '1', expiresAt: null);
    expect(await sut.read(), isNull);
  });

  test('read returns session when not expired', () async {
    await withClock(Clock.fixed(fixedNow), () async {
      stubReads(
        token: 'abc',
        id: '1',
        expiresAt: fixedNow.add(const Duration(days: 1)).toIso8601String(),
      );
      final session = await sut.read();
      expect(session, isNotNull);
      expect(session!.driverId.value, 1);
      expect(session.token, 'abc');
      expect(session.refreshToken, 'refresh');
    });
  });

  test('read clears and returns null when expired', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await withClock(Clock.fixed(fixedNow), () async {
      stubReads(
        token: 'abc',
        id: '1',
        expiresAt: fixedNow.subtract(const Duration(days: 1)).toIso8601String(),
      );
      expect(await sut.read(), isNull);
    });
    verify(() => storage.delete(key: 'driver_token')).called(1);
  });

  test('read returns null when only the refresh token is missing', () async {
    await withClock(Clock.fixed(fixedNow), () async {
      stubReads(
        token: 'abc',
        refreshToken: null,
        id: '1',
        expiresAt: fixedNow.add(const Duration(days: 1)).toIso8601String(),
      );
      expect(await sut.read(), isNull);
    });
  });

  test('clear removes the refresh token too', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await sut.clear();

    verify(() => storage.delete(key: 'driver_refresh_token')).called(1);
  });
}
