import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DriverApi {}

class _MockStore extends Mock implements TokenStore {}

void main() {
  late _MockApi api;
  late _MockStore store;
  late SessionRenewer sut;

  const AuthenticatedAccount account = AuthenticatedAccount(
    id: 7,
    email: 'driver@kinetix.test',
    role: 'courier',
    principalId: '11111111-2222-3333-4444-555555555555',
  );

  const DriverSession stored = DriverSession(
    driverId: DriverId(9),
    token: 'expired-access',
    refreshToken: 'refresh-1',
  );

  const SessionResponse refreshed = SessionResponse(
    accessToken: 'access-2',
    refreshToken: 'refresh-2',
    expiresIn: 900,
    tokenType: 'Bearer',
    user: account,
  );

  DioException dioWith(int code) => new DioException(
    requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
    response: new Response<Map<String, dynamic>>(
      requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
      statusCode: code,
    ),
  );

  setUpAll(() {
    registerFallbackValue(const RefreshRequest(refreshToken: ''));
    registerFallbackValue(
      const DriverSession(driverId: DriverId(0), token: '', refreshToken: ''),
    );
    registerFallbackValue(new DateTime(2026));
  });

  setUp(() {
    api = new _MockApi();
    store = new _MockStore();
    sut = new SessionRenewer(api, store);
    when(() => store.read()).thenAnswer((_) async => stored);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
  });

  test('trades the refresh token for a new pair and stores both', () async {
    final DateTime now = DateTime.utc(2026, 10, 19, 8);
    when(() => api.refresh(any())).thenAnswer((_) async => refreshed);

    final Result<DriverSession> res = await withClock(
      Clock.fixed(now),
      sut.renew,
    );

    expect(res, isA<Ok<DriverSession>>());
    final DriverSession renewed = (res as Ok<DriverSession>).value;
    expect(renewed.token, 'access-2');
    expect(renewed.refreshToken, 'refresh-2');
    expect(renewed.driverId, const DriverId(9));
    verify(
      () => api.refresh(const RefreshRequest(refreshToken: 'refresh-1')),
    ).called(1);
    verify(
      () => store.save(renewed, now.add(const Duration(seconds: 900))),
    ).called(1);
  });

  test(
    'sends one refresh for callers asking at once, because identity revokes a refresh token presented twice',
    () async {
      final Completer<SessionResponse> answer =
          new Completer<SessionResponse>();
      when(() => api.refresh(any())).thenAnswer((_) => answer.future);

      final Future<Result<DriverSession>> first = sut.renew();
      final Future<Result<DriverSession>> second = sut.renew();
      answer.complete(refreshed);

      expect(await first, isA<Ok<DriverSession>>());
      expect(await second, isA<Ok<DriverSession>>());
      verify(() => api.refresh(any())).called(1);
    },
  );

  test('asks again once the previous renewal has finished', () async {
    when(() => api.refresh(any())).thenAnswer((_) async => refreshed);

    await sut.renew();
    await sut.renew();

    verify(() => api.refresh(any())).called(2);
  });

  for (final int code in <int>[400, 401]) {
    test(
      '$code means the refresh token is refused: the session is cleared',
      () async {
        when(() => api.refresh(any())).thenThrow(dioWith(code));

        final Result<DriverSession> res = await sut.renew();

        expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
        verify(() => store.clear()).called(1);
      },
    );
  }

  for (final int code in <int>[429, 500, 503]) {
    test('$code is identity not answering: the session is kept', () async {
      when(() => api.refresh(any())).thenThrow(dioWith(code));

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<NetworkFailure>());
      verifyNever(() => store.clear());
      verifyNever(() => store.save(any(), any()));
    });
  }

  test('no connection is identity not answering', () async {
    when(() => api.refresh(any())).thenThrow(
      new DioException(
        requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );

    final Result<DriverSession> res = await sut.renew();

    expect((res as Err<DriverSession>).failure, isA<NetworkFailure>());
    verifyNever(() => store.clear());
  });

  test('with nothing stored there is nothing to renew', () async {
    when(() => store.read()).thenAnswer((_) async => null);

    final Result<DriverSession> res = await sut.renew();

    expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
    verifyNever(() => api.refresh(any()));
  });
}
