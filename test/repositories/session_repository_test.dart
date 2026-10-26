import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof.dart';
import 'package:fleet_pulse_mobile/services/attestation/client_proof_source.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/fleet_standing.dart';
import 'package:fleet_pulse_mobile/services/auth/session_renewer.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DriverApi {}

class _MockStore extends Mock implements TokenStore {}

class _MockRenewer extends Mock implements SessionRenewer {}

class _MockFleet extends Mock implements FleetStanding {}

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
  late _MockRenewer renewer;
  late _MockFleet fleet;
  late _Proofs proofs;
  late SessionRepositoryImpl sut;

  final Map<String, dynamic> sessionJson = <String, dynamic>{
    'accessToken': 'tok',
    'refreshToken': 'refresh',
    'expiresIn': 900,
    'tokenType': 'Bearer',
    'user': <String, dynamic>{
      'id': 7,
      'email': 'driver@kinetix.test',
      'role': 'courier',
      'principalId': '11111111-2222-3333-4444-555555555555',
    },
  };

  final Map<String, dynamic> verifiedOk = <String, dynamic>{
    ...sessionJson,
    'accessToken': 'tok-2fa',
    'refreshToken': 'refresh-2fa',
  };

  final Map<String, dynamic> registeredOk = <String, dynamic>{
    ...sessionJson,
    'accessToken': 'new-tok',
    'refreshToken': 'new-refresh',
    'driverId': 42,
  };

  const DriverProfile profile = DriverProfile(
    id: DriverId(9),
    vehiclePlate: 'B 1 ABC',
    capacityKg: 100,
    status: 'offline',
    active: true,
  );

  const DriverSession stored = DriverSession(
    driverId: DriverId(9),
    token: 'old',
    refreshToken: 'refresh',
  );

  const DriverSession renewed = DriverSession(
    driverId: DriverId(9),
    token: 'new',
    refreshToken: 'new-refresh',
  );

  const TwoFactorChallenge challenge = TwoFactorChallenge(
    challengeToken: 'challenge-1',
    expiresIn: 300,
  );

  setUpAll(() {
    registerFallbackValue(const LoginRequest(email: '', password: ''));
    registerFallbackValue(
      const TwoFactorVerifyRequest(challengeToken: '', code: ''),
    );
    registerFallbackValue(const LogoutRequest(refreshToken: ''));
    registerFallbackValue(
      const RegisterCourierRequest(
        email: '',
        password: '',
        fullName: '',
        phoneNumber: '',
        vehiclePlate: '',
        capacityKg: 0,
      ),
    );
    registerFallbackValue(
      const DriverSession(driverId: DriverId(0), token: '', refreshToken: ''),
    );
    registerFallbackValue(new DateTime(2026));
    registerFallbackValue(const DriverId(0));
  });

  setUp(() {
    api = new _MockApi();
    store = new _MockStore();
    renewer = new _MockRenewer();
    fleet = new _MockFleet();
    proofs = new _Proofs();
    sut = new SessionRepositoryImpl(
      api,
      store,
      renewer,
      fleet,
      new ClientProof(proofs),
    );
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(() => store.rebind(any())).thenAnswer((_) async {});
    when(
      () => fleet.check(any()),
    ).thenAnswer((_) async => const Ok<DriverProfile>(profile));
  });

  DioException dioWith(
    int code, [
    Map<String, dynamic>? body,
    Map<String, List<String>> headers = const <String, List<String>>{},
  ]) => new DioException(
    requestOptions: new RequestOptions(path: '/api/v1/auth'),
    response: new Response<Map<String, dynamic>>(
      requestOptions: new RequestOptions(path: '/api/v1/auth'),
      statusCode: code,
      data: body,
      headers: new Headers.fromMap(headers),
    ),
  );

  DioException delayed(int seconds) => dioWith(
    429,
    <String, dynamic>{
      'error': 'SIGN_IN_DELAYED',
      'message': 'Too many unsuccessful sign-in attempts for this account.',
      'retryAfterSeconds': seconds,
      'traceId': 'trace-1',
    },
    <String, List<String>>{
      'retry-after': <String>['$seconds'],
    },
  );

  Future<Result<LoginOutcome>> login() => sut.login(
    email: 'driver@kinetix.test',
    password: 'fixture-password-not-real',
  );

  Future<Result<DriverSession>> register() => sut.register(
    email: 'driver@kinetix.test',
    password: 'fixture-password-not-real',
    name: 'Budi Santoso',
    phone: '081200000000',
    vehiclePlate: 'B 1234 KIN',
    capacityKg: 150,
  );

  Failure failureOf<T>(Result<T> result) => (result as Err<T>).failure;

  group('currentSession', () {
    test('is the stored session while its access token is fresh', () async {
      when(() => store.read()).thenAnswer((_) async => stored);
      when(() => store.accessExpired()).thenAnswer((_) async => false);

      expect(await sut.currentSession(), stored);
      verifyNever(() => renewer.renew());
    });

    test('renews an expired access token rather than signing out', () async {
      when(() => store.read()).thenAnswer((_) async => stored);
      when(() => store.accessExpired()).thenAnswer((_) async => true);
      when(
        () => renewer.renew(),
      ).thenAnswer((_) async => const Ok<DriverSession>(renewed));

      expect(await sut.currentSession(), renewed);
    });

    test('is no session once identity refuses the refresh token', () async {
      when(() => store.read()).thenAnswer((_) async => stored);
      when(() => store.accessExpired()).thenAnswer((_) async => true);
      when(
        () => renewer.renew(),
      ).thenAnswer((_) async => const Err<DriverSession>(AuthFailure()));

      expect(await sut.currentSession(), isNull);
    });

    test(
      'keeps the stored session when identity cannot be reached, to renew later',
      () async {
        when(() => store.read()).thenAnswer((_) async => stored);
        when(() => store.accessExpired()).thenAnswer((_) async => true);
        when(
          () => renewer.renew(),
        ).thenAnswer((_) async => const Err<DriverSession>(NetworkFailure()));

        expect(await sut.currentSession(), stored);
      },
    );

    test(
      'keeps the session when identity does not accept this build, for the updated app',
      () async {
        when(() => store.read()).thenAnswer((_) async => stored);
        when(() => store.accessExpired()).thenAnswer((_) async => true);
        when(() => renewer.renew()).thenAnswer(
          (_) async => const Err<DriverSession>(AppUpdateRequiredFailure()),
        );
        when(
          () => fleet.check(any()),
        ).thenAnswer((_) async => const Err<DriverProfile>(AuthFailure()));

        expect(await sut.currentSession(), stored);
        expect(
          failureOf(await sut.standing()),
          isA<AppUpdateRequiredFailure>(),
        );
        verifyNever(() => store.clear());
      },
    );

    test('is no session when nothing is stored', () async {
      when(() => store.read()).thenAnswer((_) async => null);

      expect(await sut.currentSession(), isNull);
      verifyNever(() => renewer.renew());
    });
  });

  group('standing', () {
    test('asks the fleet with the stored access token', () async {
      when(() => store.read()).thenAnswer((_) async => stored);

      expect(await sut.standing(), isA<Ok<DriverProfile>>());
      verify(() => fleet.check('old')).called(1);
    });

    test(
      'renews once when the fleet refuses the token, then asks again',
      () async {
        when(() => store.read()).thenAnswer((_) async => stored);
        when(
          () => fleet.check('old'),
        ).thenAnswer((_) async => const Err<DriverProfile>(AuthFailure()));
        when(
          () => renewer.renew(),
        ).thenAnswer((_) async => const Ok<DriverSession>(renewed));

        expect(await sut.standing(), isA<Ok<DriverProfile>>());
        verify(() => fleet.check('new')).called(1);
      },
    );

    test(
      'a driver the fleet names differently is written over the stored one',
      () async {
        when(() => store.read()).thenAnswer(
          (_) async => const DriverSession(
            driverId: DriverId(3),
            token: 'old',
            refreshToken: 'refresh',
          ),
        );

        expect(await sut.standing(), isA<Ok<DriverProfile>>());
        verify(() => store.rebind(const DriverId(9))).called(1);
      },
    );

    test('a driver id the fleet confirms is left alone', () async {
      when(() => store.read()).thenAnswer((_) async => stored);

      await sut.standing();

      verifyNever(() => store.rebind(any()));
    });

    test('with no session is a refusal, and asks nobody', () async {
      when(() => store.read()).thenAnswer((_) async => null);

      expect(failureOf(await sut.standing()), isA<AuthFailure>());
      verifyNever(() => fleet.check(any()));
    });
  });

  group('login', () {
    test(
      'asks the fleet who it is and stores both halves of the session',
      () async {
        final DateTime now = DateTime.utc(2026, 1, 1);
        when(
          () => api.login(any(), any()),
        ).thenAnswer((_) async => sessionJson);

        final Result<LoginOutcome> res = await withClock(
          Clock.fixed(now),
          login,
        );

        expect((res as Ok<LoginOutcome>).value, isA<LoggedIn>());
        final List<dynamic> captured = verify(
          () => store.save(captureAny(), captureAny()),
        ).captured;
        final DriverSession saved = captured[0] as DriverSession;
        expect(saved.token, 'tok');
        expect(saved.refreshToken, 'refresh');
        expect(saved.driverId, const DriverId(9));
        expect(captured[1] as DateTime, now.add(const Duration(seconds: 900)));
      },
    );

    test(
      'authorises the fleet call with the token identity just issued',
      () async {
        when(
          () => api.login(any(), any()),
        ).thenAnswer((_) async => sessionJson);

        await login();

        verify(() => fleet.check('tok')).called(1);
      },
    );

    test('401 is a wrong email or password', () async {
      when(() => api.login(any(), any())).thenThrow(dioWith(401));

      final Failure f = failureOf(await login());

      expect(f, isA<AuthFailure>());
      expect(f.message, contains('email or password'));
    });

    test('503 says sign-in is unavailable, not how to register', () async {
      when(() => api.login(any(), any())).thenThrow(
        dioWith(503, <String, dynamic>{'error': 'DATABASE_UNAVAILABLE'}),
      );

      final Failure f = failureOf(await login());

      expect(f, isA<ServiceUnavailableFailure>());
      expect(f.message, contains('Signing in'));
      expect(f.message, isNot(contains('submit the same details')));
    });

    test('429 with no stated wait asks the courier to wait', () async {
      when(() => api.login(any(), any())).thenThrow(dioWith(429));

      expect(failureOf(await login()).message, contains('Wait a minute'));
    });

    test(
      'SIGN_IN_DELAYED is the wait identity names, never a wrong password',
      () async {
        when(() => api.login(any(), any())).thenThrow(delayed(8));

        final Failure f = failureOf(await login());

        expect(f, isA<SignInDelayedFailure>());
        expect((f as SignInDelayedFailure).wait, const Duration(seconds: 8));
        expect(f.message, 'Too many sign-in attempts. Try again in 8 seconds.');
        expect(f.message, isNot(contains('password')));
        verify(() => api.login(any(), any())).called(1);
        verifyNever(() => store.save(any(), any()));
        verifyNever(() => store.clear());
      },
    );

    test('a 429 that names only Retry-After waits that long', () async {
      when(() => api.login(any(), any())).thenThrow(
        dioWith(
          429,
          <String, dynamic>{
            'statusCode': 429,
            'message': 'ThrottlerException: Too Many Requests',
          },
          <String, List<String>>{
            'Retry-After': <String>['30'],
          },
        ),
      );

      final Failure f = failureOf(await login());

      expect((f as SignInDelayedFailure).wait, const Duration(seconds: 30));
    });

    test(
      'an administrator is told this app is for couriers, and nothing is kept',
      () async {
        when(() => api.login(any(), any())).thenAnswer(
          (_) async => <String, dynamic>{
            'mfaEnrolmentRequired': true,
            'enrolmentToken': 'enrolment-token',
            'tokenType': 'Bearer',
            'expiresIn': 600,
            'userId': 3,
          },
        );

        final Failure f = failureOf(await login());

        expect(f, isA<AdminAccountFailure>());
        expect(f.message, contains('courier'));
        verifyNever(() => store.save(any(), any()));
        verifyNever(() => fleet.check(any()));
        verifyNever(() => api.logout(any(), any()));
      },
    );

    test("400 shows identity's validation messages", () async {
      when(() => api.login(any(), any())).thenThrow(
        dioWith(400, <String, dynamic>{
          'message': <String>['email must be an email'],
        }),
      );

      expect(failureOf(await login()).message, 'email must be an email');
    });

    test('unexpected error maps to NetworkFailure', () async {
      when(() => api.login(any(), any())).thenThrow(new Exception('boom'));

      expect(failureOf(await login()), isA<NetworkFailure>());
    });
  });

  group('login with a second factor', () {
    final Map<String, dynamic> challengeJson = <String, dynamic>{
      'mfaRequired': true,
      'challengeToken': 'challenge-1',
      'expiresIn': 300,
    };

    test('asks for the code and stores nothing yet', () async {
      when(
        () => api.login(any(), any()),
      ).thenAnswer((_) async => challengeJson);

      final Result<LoginOutcome> res = await login();

      final LoginOutcome outcome = (res as Ok<LoginOutcome>).value;
      expect(
        (outcome as SecondFactorRequired).challenge,
        const TwoFactorChallenge(challengeToken: 'challenge-1', expiresIn: 300),
      );
      verifyNever(() => store.save(any(), any()));
      verifyNever(() => fleet.check(any()));
    });

    test(
      'the code goes to identity with the challenge, then the fleet is asked and the session stored',
      () async {
        when(
          () => api.verifyTwoFactor(any(), any()),
        ).thenAnswer((_) async => verifiedOk);

        final Result<DriverSession> res = await sut.verifySecondFactor(
          challenge: challenge,
          code: '123456',
        );

        expect((res as Ok<DriverSession>).value.token, 'tok-2fa');
        final TwoFactorVerifyRequest sent =
            verify(
                  () => api.verifyTwoFactor(any(), captureAny()),
                ).captured.single
                as TwoFactorVerifyRequest;
        expect(sent.challengeToken, 'challenge-1');
        expect(sent.code, '123456');
        verify(() => fleet.check('tok-2fa')).called(1);
        verify(() => store.save(any(), any())).called(1);
      },
    );

    test("a wrong code shows identity's reason and stores nothing", () async {
      when(() => api.verifyTwoFactor(any(), any())).thenThrow(
        dioWith(401, <String, dynamic>{'message': 'That code is not valid'}),
      );

      final Result<DriverSession> res = await sut.verifySecondFactor(
        challenge: challenge,
        code: '000000',
      );

      final Failure f = failureOf(res);
      expect(f, isA<RefusedFailure>());
      expect(f.message, 'That code is not valid');
      verifyNever(() => store.save(any(), any()));
    });

    test(
      'a challenge that has used its five attempts sends the courier back to the password',
      () async {
        when(() => api.verifyTwoFactor(any(), any())).thenThrow(
          dioWith(401, <String, dynamic>{
            'statusCode': 401,
            'message': 'This challenge allows no more attempts; sign in again',
            'error': 'Unauthorized',
            'traceId': 'trace-1',
          }),
        );

        final Failure f = failureOf(
          await sut.verifySecondFactor(challenge: challenge, code: '123456'),
        );

        expect(f, isA<ChallengeSpentFailure>());
        expect(f.message, contains('Too many wrong codes'));
        expect(f.message, contains('password'));
        verify(() => api.verifyTwoFactor(any(), any())).called(1);
        verifyNever(() => store.save(any(), any()));
      },
    );

    for (final String said in <String>[
      'That code has already been used; sign in again with the next one',
      'This challenge has already been answered; sign in again',
      'Invalid token',
    ]) {
      test('"$said" ends the challenge as well', () async {
        when(() => api.verifyTwoFactor(any(), any())).thenThrow(
          dioWith(401, <String, dynamic>{
            'statusCode': 401,
            'message': said,
            'error': 'Unauthorized',
          }),
        );

        final Failure f = failureOf(
          await sut.verifySecondFactor(challenge: challenge, code: '123456'),
        );

        expect(f, isA<ChallengeSpentFailure>());
        expect(f.message, contains('password'));
      });
    }

    test(
      'SIGN_IN_DELAYED keeps the challenge: identity counted no attempt',
      () async {
        when(() => api.verifyTwoFactor(any(), any())).thenThrow(delayed(4));

        final Failure f = failureOf(
          await sut.verifySecondFactor(challenge: challenge, code: '123456'),
        );

        expect((f as SignInDelayedFailure).wait, const Duration(seconds: 4));
        verifyNever(() => store.save(any(), any()));
      },
    );
  });

  group('login of an account that cannot drive yet', () {
    test(
      'a pending account keeps the fresh session for the waiting screen',
      () async {
        when(
          () => api.login(any(), any()),
        ).thenAnswer((_) async => sessionJson);
        when(() => fleet.check(any())).thenAnswer(
          (_) async => const Err<DriverProfile>(PendingApprovalFailure()),
        );

        expect(failureOf(await login()), isA<PendingApprovalFailure>());

        final DriverSession saved =
            verify(() => store.save(captureAny(), any())).captured.single
                as DriverSession;
        expect(saved.token, 'tok');
        expect(saved.refreshToken, 'refresh');
        expect(saved.driverId, isNull);
        verifyNever(() => api.logout(any(), any()));
      },
    );

    final Map<String, Failure> refusals = <String, Failure>{
      'an unfinished registration': const RegistrationIncompleteFailure(),
      'a refused session': const AuthFailure(),
      'a fleet that cannot be asked': const ServiceUnavailableFailure('down'),
      'no answer': const NetworkFailure(),
    };

    for (final MapEntry<String, Failure> refusal in refusals.entries) {
      test(
        '${refusal.key} at sign-in revokes the fresh session at identity and stores nothing',
        () async {
          when(
            () => api.login(any(), any()),
          ).thenAnswer((_) async => sessionJson);
          when(
            () => fleet.check(any()),
          ).thenAnswer((_) async => new Err<DriverProfile>(refusal.value));
          when(() => api.logout(any(), any())).thenAnswer((_) async {});

          expect(failureOf(await login()), refusal.value);

          verifyNever(() => store.save(any(), any()));
          final List<dynamic> sent = verify(
            () => api.logout(captureAny(), captureAny()),
          ).captured;
          expect(sent[0], 'Bearer tok');
          expect((sent[1] as LogoutRequest).refreshToken, 'refresh');
        },
      );
    }

    test(
      'a refused second factor admission is revoked at identity as well',
      () async {
        when(
          () => api.verifyTwoFactor(any(), any()),
        ).thenAnswer((_) async => verifiedOk);
        when(() => fleet.check(any())).thenAnswer(
          (_) async =>
              const Err<DriverProfile>(RegistrationIncompleteFailure()),
        );
        when(() => api.logout(any(), any())).thenAnswer((_) async {});

        await sut.verifySecondFactor(challenge: challenge, code: '123456');

        verify(() => api.logout('Bearer tok-2fa', any())).called(1);
        verifyNever(() => store.save(any(), any()));
      },
    );
  });

  group('register', () {
    test('is one call, and this app is no longer the coordinator', () async {
      when(
        () => api.registerCourier(any(), any()),
      ).thenAnswer((_) async => registeredOk);

      final Result<DriverSession> res = await register();

      expect(res, isA<Ok<DriverSession>>());
      verify(() => api.registerCourier(any(), any())).called(1);
      verifyNever(() => api.login(any(), any()));
      verifyNever(() => fleet.check(any()));
    });

    test(
      'keeps the driver signed in, so the waiting screen needs no second password',
      () async {
        final DateTime now = DateTime.utc(2026, 1, 1);
        when(
          () => api.registerCourier(any(), any()),
        ).thenAnswer((_) async => registeredOk);

        await withClock(Clock.fixed(now), register);

        final List<dynamic> captured = verify(
          () => store.save(captureAny(), captureAny()),
        ).captured;
        final DriverSession saved = captured[0] as DriverSession;
        expect(saved.token, 'new-tok');
        expect(saved.refreshToken, 'new-refresh');
        expect(saved.driverId, const DriverId(42));
        expect(captured[1] as DateTime, now.add(const Duration(seconds: 900)));
      },
    );

    test('sends the person to identity and the vehicle through it', () async {
      when(
        () => api.registerCourier(any(), any()),
      ).thenAnswer((_) async => registeredOk);

      await register();

      final RegisterCourierRequest sent =
          verify(() => api.registerCourier(any(), captureAny())).captured.single
              as RegisterCourierRequest;
      expect(sent.fullName, 'Budi Santoso');
      expect(sent.phoneNumber, '081200000000');
      expect(sent.vehiclePlate, 'B 1234 KIN');
      expect(sent.capacityKg, 150);
    });

    test('409 carries the reason the server gave', () async {
      when(() => api.registerCourier(any(), any())).thenThrow(
        dioWith(409, <String, dynamic>{
          'message': 'An account with that email address already exists',
        }),
      );

      final Failure f = failureOf(await register());
      expect(f, isA<RefusedFailure>());
      expect(f.message, contains('already exists'));
    });

    test(
      'a 400 after the account was made says to submit again with the same email and password',
      () async {
        when(() => api.registerCourier(any(), any())).thenThrow(
          dioWith(400, <String, dynamic>{
            'error': 'INVALID_VEHICLE_PLATE',
            'message':
                'Your account exists, but the fleet refused the vehicle: plate '
                'taken. Correct the vehicle details and submit again with the '
                'same email and password; the account will be reused.',
            'accountExists': true,
          }),
        );

        final Failure f = failureOf(await register());
        expect(f, isA<RefusedFailure>());
        expect(f.message, contains('same email and password'));
      },
    );

    test("a validation 400 shows each of identity's messages", () async {
      when(() => api.registerCourier(any(), any())).thenThrow(
        dioWith(400, <String, dynamic>{
          'message': <String>[
            'password must be at most 72 bytes, which is all bcrypt reads',
            'phoneNumber must be 8 to 15 digits, optionally after a +',
          ],
        }),
      );

      final String message = failureOf(await register()).message;
      expect(message, contains('72 bytes'));
      expect(message, contains('8 to 15 digits'));
    });

    test('503 tells the driver to submit the same details again', () async {
      when(() => api.registerCourier(any(), any())).thenThrow(
        dioWith(503, <String, dynamic>{
          'error': 'FLEET_UNAVAILABLE',
          'message':
              'Your account exists, but the fleet could not be reached to file '
              'your vehicle. Submit the same details again to finish.',
          'accountExists': true,
        }),
      );

      final Failure f = failureOf(await register());
      expect(f, isA<ServiceUnavailableFailure>());
      expect(f.message, contains('again'));
    });

    test('503 with no body still says something actionable', () async {
      when(() => api.registerCourier(any(), any())).thenThrow(dioWith(503));

      expect(failureOf(await register()).message, contains('again'));
    });

    test(
      'SIGN_IN_DELAYED on a resumed registration is a wait, not a refusal',
      () async {
        when(() => api.registerCourier(any(), any())).thenThrow(delayed(16));

        final Failure f = failureOf(await register());

        expect((f as SignInDelayedFailure).wait, const Duration(seconds: 16));
        verifyNever(() => store.save(any(), any()));
      },
    );

    test('stores nothing when registration fails', () async {
      when(() => api.registerCourier(any(), any())).thenThrow(dioWith(409));

      await register();

      verifyNever(() => store.save(any(), any()));
    });
  });

  group('answers this app cannot read', () {
    test(
      'a registration whose answer cannot be read asks the courier to sign in, not to check the network',
      () async {
        when(
          () => api.registerCourier(any(), any()),
        ).thenAnswer((_) async => <String, dynamic>{'accessToken': 7});

        final Failure f = failureOf(await register());

        expect(f, isNot(isA<NetworkFailure>()));
        expect(f.message, contains('sign in'));
        verifyNever(() => store.save(any(), any()));
      },
    );

    test(
      'an accepted code whose answer cannot be read asks the courier to sign in again',
      () async {
        when(
          () => api.verifyTwoFactor(any(), any()),
        ).thenAnswer((_) async => <String, dynamic>{'accessToken': 7});

        final Failure f = failureOf(
          await sut.verifySecondFactor(challenge: challenge, code: '123456'),
        );

        expect(f, isNot(isA<NetworkFailure>()));
        expect(f.message, contains('Sign in again'));
      },
    );
  });

  group('client proof', () {
    DioException identitySaid(int code, String error) =>
        dioWith(code, <String, dynamic>{'error': error, 'message': 'refused'});

    test(
      'every sign-in names the app and carries an App Check token',
      () async {
        when(
          () => api.login(any(), any()),
        ).thenAnswer((_) async => sessionJson);

        await login();

        verify(() => api.login('proof-cached', any())).called(1);
      },
    );

    for (final String code in <String>[
      'CLIENT_PROOF_REQUIRED',
      'CLIENT_PROOF_INVALID',
    ]) {
      test('$code is answered with one fresh token and one retry', () async {
        when(
          () => api.login('proof-cached', any()),
        ).thenThrow(identitySaid(401, code));
        when(
          () => api.login('proof-fresh-1', any()),
        ).thenAnswer((_) async => sessionJson);

        final Result<LoginOutcome> res = await login();

        expect(res, isA<Ok<LoginOutcome>>());
        expect(proofs.fresh, 1);
      });
    }

    test(
      'a proof refused twice is an untrusted app, never a wrong password',
      () async {
        when(
          () => api.login(any(), any()),
        ).thenThrow(identitySaid(401, 'CLIENT_PROOF_INVALID'));

        final Failure f = failureOf(await login());

        expect(f, isA<UntrustedClientFailure>());
        expect(f.message, isNot(contains('password')));
        verify(() => api.login(any(), any())).called(2);
      },
    );

    test('CLIENT_PROOF_UNAVAILABLE is try again later', () async {
      when(
        () => api.login(any(), any()),
      ).thenThrow(identitySaid(503, 'CLIENT_PROOF_UNAVAILABLE'));

      final Failure f = failureOf(await login());

      expect(f, isA<ServiceUnavailableFailure>());
      verify(() => api.login(any(), any())).called(1);
    });

    test(
      'a phone that cannot get a token asks identity nothing and says try again',
      () async {
        proofs.failure = new Exception('Play Integrity is not available');

        final Failure f = failureOf(await login());

        expect(f, isA<ServiceUnavailableFailure>());
        verifyNever(() => api.login(any(), any()));
      },
    );

    test(
      'the second factor and registration carry the proof as well',
      () async {
        when(
          () => api.verifyTwoFactor(any(), any()),
        ).thenAnswer((_) async => verifiedOk);
        when(
          () => api.registerCourier(any(), any()),
        ).thenAnswer((_) async => registeredOk);

        await sut.verifySecondFactor(challenge: challenge, code: '123456');
        await register();

        verify(() => api.verifyTwoFactor('proof-cached', any())).called(1);
        verify(() => api.registerCourier('proof-cached', any())).called(1);
      },
    );

    for (final String code in <String>['UNKNOWN_CLIENT', 'CLIENT_REQUIRED']) {
      test(
        '$code asks for an update, not for other credentials, and is not retried',
        () async {
          when(
            () => api.login(any(), any()),
          ).thenThrow(identitySaid(400, code));
          when(
            () => api.verifyTwoFactor(any(), any()),
          ).thenThrow(identitySaid(400, code));
          when(
            () => api.registerCourier(any(), any()),
          ).thenThrow(identitySaid(400, code));

          final List<Failure> failures = <Failure>[
            failureOf(await login()),
            failureOf(
              await sut.verifySecondFactor(
                challenge: challenge,
                code: '123456',
              ),
            ),
            failureOf(await register()),
          ];

          for (final Failure f in failures) {
            expect(f, isA<AppUpdateRequiredFailure>());
          }
          verify(() => api.login(any(), any())).called(1);
          verify(() => api.verifyTwoFactor(any(), any())).called(1);
          verify(() => api.registerCourier(any(), any())).called(1);
          expect(proofs.fresh, 0);
        },
      );
    }
  });

  group('logout', () {
    test(
      'ends the session at identity with its refresh token, then forgets it',
      () async {
        when(() => store.read()).thenAnswer((_) async => stored);
        when(() => api.logout(any(), any())).thenAnswer((_) async {});

        await sut.logout();

        final List<dynamic> sent = verify(
          () => api.logout(captureAny(), captureAny()),
        ).captured;
        expect(sent[0], 'Bearer old');
        expect((sent[1] as LogoutRequest).refreshToken, 'refresh');
        verify(() => store.clear()).called(1);
      },
    );

    test('forgets the session even when identity cannot be reached', () async {
      when(() => store.read()).thenAnswer((_) async => stored);
      when(() => api.logout(any(), any())).thenThrow(
        new DioException(requestOptions: new RequestOptions(path: '/logout')),
      );

      await sut.logout();

      verify(() => store.clear()).called(1);
    });

    test(
      'renews an expired access token once to end the session, then forgets it',
      () async {
        when(() => store.read()).thenAnswer((_) async => stored);
        when(() => api.logout('Bearer old', any())).thenThrow(dioWith(401));
        when(() => api.logout('Bearer new', any())).thenAnswer((_) async {});
        when(
          () => renewer.renew(),
        ).thenAnswer((_) async => const Ok<DriverSession>(renewed));

        await sut.logout();

        verify(() => api.logout('Bearer new', any())).called(1);
        verify(() => store.clear()).called(1);
      },
    );

    test('with nothing stored, asks identity nothing', () async {
      when(() => store.read()).thenAnswer((_) async => null);

      await sut.logout();

      verifyNever(() => api.logout(any(), any()));
      verify(() => store.clear()).called(1);
    });
  });
}
