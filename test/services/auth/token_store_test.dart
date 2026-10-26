import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockStorage storage;
  late TokenStore sut;
  final DateTime fixedNow = DateTime.utc(2026, 1, 1);

  const DriverSession session = DriverSession(
    driverId: DriverId(1),
    token: 'abc',
    refreshToken: 'refresh',
  );

  setUp(() {
    storage = new _MockStorage();
    sut = new TokenStore(storage);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
  });

  void stubRecord(Map<String, Object?>? record) {
    when(
      () => storage.read(key: 'driver_session'),
    ).thenAnswer((_) async => record == null ? null : jsonEncode(record));
  }

  Map<String, Object?> recordExpiringAt(DateTime expiresAt) =>
      <String, Object?>{
        'token': 'abc',
        'refresh_token': 'refresh',
        'driver_id': 1,
        'expires_at': expiresAt.toIso8601String(),
      };

  test(
    'save is one write, so a crash cannot keep one half of a rotated pair',
    () async {
      await sut.save(session, fixedNow);

      final String written =
          verify(
                () => storage.write(
                  key: 'driver_session',
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      expect(jsonDecode(written), <String, Object?>{
        'token': 'abc',
        'refresh_token': 'refresh',
        'driver_id': 1,
        'expires_at': '2026-01-01T00:00:00.000Z',
      });
      verifyNoMoreInteractions(storage);
    },
  );

  test('what save wrote, read returns', () async {
    await sut.save(session, fixedNow);
    final String written =
        verify(
              () => storage.write(
                key: 'driver_session',
                value: captureAny(named: 'value'),
              ),
            ).captured.single
            as String;
    when(
      () => storage.read(key: 'driver_session'),
    ).thenAnswer((_) async => written);

    expect(await sut.read(), session);
  });

  test('read returns null when nothing is stored', () async {
    stubRecord(null);

    expect(await sut.read(), isNull);
  });

  test('read returns null when a field is missing', () async {
    stubRecord(recordExpiringAt(fixedNow)..remove('refresh_token'));

    expect(await sut.read(), isNull);
  });

  test('read returns null for a record that is not JSON', () async {
    when(
      () => storage.read(key: 'driver_session'),
    ).thenAnswer((_) async => 'not json');

    expect(await sut.read(), isNull);
  });

  test(
    'read keeps the session after the access token expires, for the refresh token to renew',
    () async {
      await withClock(Clock.fixed(fixedNow), () async {
        stubRecord(
          recordExpiringAt(fixedNow.subtract(const Duration(days: 1))),
        );

        final DriverSession? read = await sut.read();

        expect(read!.refreshToken, 'refresh');
      });
      verifyNever(() => storage.delete(key: any(named: 'key')));
    },
  );

  test('accessExpired is false before the access token expires', () async {
    await withClock(Clock.fixed(fixedNow), () async {
      stubRecord(recordExpiringAt(fixedNow.add(const Duration(minutes: 1))));
      expect(await sut.accessExpired(), isFalse);
    });
  });

  test('accessExpired is true once the access token has expired', () async {
    await withClock(Clock.fixed(fixedNow), () async {
      stubRecord(recordExpiringAt(fixedNow));
      expect(await sut.accessExpired(), isTrue);
    });
  });

  test('accessExpired is true when nothing is stored', () async {
    stubRecord(null);
    expect(await sut.accessExpired(), isTrue);
  });

  test('clear removes the session and the keys older builds wrote', () async {
    await sut.clear();

    for (final String key in <String>[
      'driver_session',
      'driver_token',
      'driver_refresh_token',
      'driver_id',
      'expires_at',
    ]) {
      verify(() => storage.delete(key: key)).called(1);
    }
  });
  test(
    'a session the fleet has not approved is kept without a driver',
    () async {
      stubRecord(recordExpiringAt(fixedNow)..['driver_id'] = null);

      final DriverSession? read = await sut.read();

      expect(read!.driverId, isNull);
      expect(read.refreshToken, 'refresh');
    },
  );

  test('a driver id that is not a number is not a session', () async {
    stubRecord(recordExpiringAt(fixedNow)..['driver_id'] = 'one');

    expect(await sut.read(), isNull);
  });

  test(
    'rebind writes the fleet driver over the stored one, keeping tokens and expiry',
    () async {
      stubRecord(recordExpiringAt(fixedNow)..['driver_id'] = null);

      await sut.rebind(const DriverId(9));

      final String written =
          verify(
                () => storage.write(
                  key: 'driver_session',
                  value: captureAny(named: 'value'),
                ),
              ).captured.single
              as String;
      expect(jsonDecode(written), <String, Object?>{
        'token': 'abc',
        'refresh_token': 'refresh',
        'driver_id': 9,
        'expires_at': '2026-01-01T00:00:00.000Z',
      });
    },
  );

  test('rebind with nothing stored writes nothing', () async {
    stubRecord(null);

    await sut.rebind(const DriverId(9));

    verifyNever(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    );
  });
}
