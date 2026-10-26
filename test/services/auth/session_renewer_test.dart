import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_source.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DriverApi {}

class _MockStore extends Mock implements TokenStore {}

class _Proofs implements ClientProofSource {
  int fresh = 0;
  Object? failure;

  @override
  Future<String?> token({required bool forceRefresh}) async {
    final Object? failing = failure;

    if (failing != null) {
      throw failing;
    }

    if (!forceRefresh) {
      return 'proof-cached';
    }

    fresh++;

    return 'proof-fresh-$fresh';
  }
}

void main() {
  late _MockApi api;
  late _MockStore store;
  late _Proofs proofs;
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

  final Map<String, dynamic> refreshed = <String, dynamic>{
    'accessToken': 'access-2',
    'refreshToken': 'refresh-2',
    'expiresIn': 900,
    'tokenType': 'Bearer',
    'user': account.toJson(),
  };

  DioException dioWith(int code, [String? error]) => new DioException(
    requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
    type: DioExceptionType.badResponse,
    response: new Response<Map<String, dynamic>>(
      requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
      statusCode: code,
      data: error == null ? null : <String, dynamic>{'error': error},
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
    proofs = new _Proofs();
    sut = new SessionRenewer(api, store, new ClientProof(proofs));
    when(() => store.read()).thenAnswer((_) async => stored);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
  });

  test('trades the refresh token for a new pair and stores both', () async {
    final DateTime now = DateTime.utc(2026, 10, 19, 8);
    when(() => api.refresh(any(), any())).thenAnswer((_) async => refreshed);

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
      () => api.refresh(
        'proof-cached',
        const RefreshRequest(refreshToken: 'refresh-1'),
      ),
    ).called(1);
    verify(
      () => store.save(renewed, now.add(const Duration(seconds: 900))),
    ).called(1);
  });

  test(
    'sends one refresh for callers asking at once, because identity revokes a refresh token presented twice',
    () async {
      final Completer<Map<String, dynamic>> answer =
          new Completer<Map<String, dynamic>>();
      when(() => api.refresh(any(), any())).thenAnswer((_) => answer.future);

      final Future<Result<DriverSession>> first = sut.renew();
      final Future<Result<DriverSession>> second = sut.renew();
      answer.complete(refreshed);

      expect(await first, isA<Ok<DriverSession>>());
      expect(await second, isA<Ok<DriverSession>>());
      verify(() => api.refresh(any(), any())).called(1);
    },
  );

  test('asks again once the previous renewal has finished', () async {
    when(() => api.refresh(any(), any())).thenAnswer((_) async => refreshed);

    await sut.renew();
    await sut.renew();

    verify(() => api.refresh(any(), any())).called(2);
  });

  for (final int code in <int>[400, 401, 403]) {
    test(
      '$code means the refresh token is refused: the session is cleared',
      () async {
        when(() => api.refresh(any(), any())).thenThrow(dioWith(code));

        final Result<DriverSession> res = await sut.renew();

        expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
        verify(() => store.clear()).called(1);
      },
    );
  }

  for (final int code in <int>[429, 502, 503]) {
    test('$code is identity not answering: the session is kept', () async {
      when(() => api.refresh(any(), any())).thenThrow(dioWith(code));

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<NetworkFailure>());
      verifyNever(() => store.clear());
      verifyNever(() => store.save(any(), any()));
    });
  }

  for (final int code in <int>[500, 504]) {
    test(
      '$code leaves it unknown whether the token was spent: the session is lost, never presented again',
      () async {
        when(() => api.refresh(any(), any())).thenThrow(dioWith(code));

        final Result<DriverSession> res = await sut.renew();

        final Failure failure = (res as Err<DriverSession>).failure;
        expect(failure, isA<AuthFailure>());
        expect(failure.message, contains('Sign in again'));
        verify(() => store.clear()).called(1);
      },
    );
  }

  test(
    'an answer lost after the request was sent ends the session instead of reusing the spent token',
    () async {
      when(() => api.refresh(any(), any())).thenThrow(
        new DioException(
          requestOptions: new RequestOptions(path: '/api/v1/auth/refresh'),
          type: DioExceptionType.receiveTimeout,
        ),
      );

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
      verify(() => store.clear()).called(1);
      verifyNever(() => store.save(any(), any()));
    },
  );

  test(
    'a 2xx this app cannot read ends the session: identity has already spent the token',
    () async {
      when(
        () => api.refresh(any(), any()),
      ).thenAnswer((_) async => <String, dynamic>{'accessToken': 'access-2'});

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
      verify(() => store.clear()).called(1);
    },
  );

  test('no connection is identity not answering', () async {
    when(() => api.refresh(any(), any())).thenThrow(
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
    verifyNever(() => api.refresh(any(), any()));
  });
  for (final String code in <String>[
    'CLIENT_PROOF_REQUIRED',
    'CLIENT_PROOF_INVALID',
  ]) {
    test(
      '$code is answered with one fresh token and one retry, the same refresh token',
      () async {
        when(
          () => api.refresh('proof-cached', any()),
        ).thenThrow(dioWith(401, code));
        when(
          () => api.refresh('proof-fresh-1', any()),
        ).thenAnswer((_) async => refreshed);

        final Result<DriverSession> res = await sut.renew();

        expect(res, isA<Ok<DriverSession>>());
        verify(
          () => api.refresh(
            any(),
            const RefreshRequest(refreshToken: 'refresh-1'),
          ),
        ).called(2);
      },
    );
  }

  test(
    'a proof refused twice ends the session: this app cannot renew it',
    () async {
      when(
        () => api.refresh(any(), any()),
      ).thenThrow(dioWith(401, 'CLIENT_PROOF_INVALID'));

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
      verify(() => api.refresh(any(), any())).called(2);
      verify(() => store.clear()).called(1);
    },
  );

  test(
    'CLIENT_MISMATCH ends the session once, without a fresh proof or a retry',
    () async {
      when(
        () => api.refresh(any(), any()),
      ).thenThrow(dioWith(401, 'CLIENT_MISMATCH'));

      final Result<DriverSession> res = await sut.renew();

      final Failure failure = (res as Err<DriverSession>).failure;
      expect(failure, isA<AuthFailure>());
      expect(failure.message, contains('Sign in again'));
      expect(failure.message, isNot(contains('Google Play')));
      verify(() => api.refresh(any(), any())).called(1);
      expect(proofs.fresh, 0);
      verify(() => store.clear()).called(1);
    },
  );

  for (final String code in <String>['UNKNOWN_CLIENT', 'CLIENT_REQUIRED']) {
    test(
      '$code asks for an update and keeps the unspent session for the updated app',
      () async {
        when(() => api.refresh(any(), any())).thenThrow(dioWith(400, code));

        final Result<DriverSession> res = await sut.renew();

        expect(
          (res as Err<DriverSession>).failure,
          isA<AppUpdateRequiredFailure>(),
        );
        verify(() => api.refresh(any(), any())).called(1);
        expect(proofs.fresh, 0);
        verifyNever(() => store.clear());
      },
    );
  }

  test('any other 400 is still a refusal that ends the session', () async {
    when(() => api.refresh(any(), any())).thenThrow(dioWith(400));

    final Result<DriverSession> res = await sut.renew();

    expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
    verify(() => store.clear()).called(1);
  });

  test(
    'CLIENT_PROOF_UNAVAILABLE is try again later, never a sign-out',
    () async {
      when(
        () => api.refresh(any(), any()),
      ).thenThrow(dioWith(503, 'CLIENT_PROOF_UNAVAILABLE'));

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<NetworkFailure>());
      verifyNever(() => store.clear());
    },
  );

  test(
    'a phone that cannot get a token keeps the session and sends nothing',
    () async {
      proofs.failure = new Exception('attestation failed');

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<NetworkFailure>());
      verifyNever(() => api.refresh(any(), any()));
      verifyNever(() => store.clear());
    },
  );

  test(
    'a 403 at refresh ends the session cleanly instead of being retried forever',
    () async {
      when(() => api.refresh(any(), any())).thenThrow(dioWith(403));

      final Result<DriverSession> res = await sut.renew();

      expect((res as Err<DriverSession>).failure, isA<AuthFailure>());
      verify(() => store.clear()).called(1);
    },
  );

  test('a renewal keeps a session whose driver is not known yet', () async {
    when(() => store.read()).thenAnswer(
      (_) async => const DriverSession(
        driverId: null,
        token: 'pending-access',
        refreshToken: 'refresh-1',
      ),
    );
    when(() => api.refresh(any(), any())).thenAnswer((_) async => refreshed);

    final Result<DriverSession> res = await sut.renew();

    expect((res as Ok<DriverSession>).value.driverId, isNull);
  });
}
