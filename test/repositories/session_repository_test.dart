import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository_impl.dart';
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

void main() {
  late _MockApi api;
  late _MockStore store;
  late _MockRenewer renewer;
  late _MockFleet fleet;
  late SessionRepositoryImpl sut;

  const AuthenticatedAccount account = AuthenticatedAccount(
    id: 7,
    email: 'driver@kinetix.test',
    role: 'courier',
    principalId: '11111111-2222-3333-4444-555555555555',
  );

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

  const SessionResponse verifiedOk = SessionResponse(
    accessToken: 'tok-2fa',
    refreshToken: 'refresh-2fa',
    expiresIn: 900,
    tokenType: 'Bearer',
    user: account,
  );

  const CourierRegistrationResponse registeredOk = CourierRegistrationResponse(
    accessToken: 'new-tok',
    refreshToken: 'new-refresh',
    expiresIn: 900,
    tokenType: 'Bearer',
    user: account,
    driverId: DriverId(42),
  );

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
  });

  setUp(() {
    api = new _MockApi();
    store = new _MockStore();
    renewer = new _MockRenewer();
    fleet = new _MockFleet();
    sut = new SessionRepositoryImpl(api, store, renewer, fleet);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
    when(() => store.clear()).thenAnswer((_) async {});
    when(
      () => fleet.check(any()),
    ).thenAnswer((_) async => const Ok<DriverProfile>(profile));
  });

  DioException dioWith(int code, [Map<String, dynamic>? body]) =>
      new DioException(
        requestOptions: new RequestOptions(path: '/api/v1/auth'),
        response: new Response<Map<String, dynamic>>(
          requestOptions: new RequestOptions(path: '/api/v1/auth'),
          statusCode: code,
          data: body,
        ),
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
        when(() => api.login(any())).thenAnswer((_) async => sessionJson);

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
        when(() => api.login(any())).thenAnswer((_) async => sessionJson);

        await login();

        verify(() => fleet.check('tok')).called(1);
      },
    );

    test('401 is a wrong email or password', () async {
      when(() => api.login(any())).thenThrow(dioWith(401));

      final Failure f = failureOf(await login());

      expect(f, isA<AuthFailure>());
      expect(f.message, contains('email or password'));
    });

    test('503 says sign-in is unavailable, not how to register', () async {
      when(() => api.login(any())).thenThrow(
        dioWith(503, <String, dynamic>{'error': 'DATABASE_UNAVAILABLE'}),
      );

      final Failure f = failureOf(await login());

      expect(f, isA<ServiceUnavailableFailure>());
      expect(f.message, contains('Signing in'));
      expect(f.message, isNot(contains('submit the same details')));
    });

    test('429 asks the courier to wait', () async {
      when(() => api.login(any())).thenThrow(dioWith(429));

      expect(failureOf(await login()).message, contains('Wait a minute'));
    });

    test("400 shows identity's validation messages", () async {
      when(() => api.login(any())).thenThrow(
        dioWith(400, <String, dynamic>{
          'message': <String>['email must be an email'],
        }),
      );

      expect(failureOf(await login()).message, 'email must be an email');
    });

    test('unexpected error maps to NetworkFailure', () async {
      when(() => api.login(any())).thenThrow(new Exception('boom'));

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
      when(() => api.login(any())).thenAnswer((_) async => challengeJson);

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
          () => api.verifyTwoFactor(any()),
        ).thenAnswer((_) async => verifiedOk);

        final Result<DriverSession> res = await sut.verifySecondFactor(
          challenge: challenge,
          code: '123456',
        );

        expect((res as Ok<DriverSession>).value.token, 'tok-2fa');
        final TwoFactorVerifyRequest sent =
            verify(() => api.verifyTwoFactor(captureAny())).captured.single
                as TwoFactorVerifyRequest;
        expect(sent.challengeToken, 'challenge-1');
        expect(sent.code, '123456');
        verify(() => fleet.check('tok-2fa')).called(1);
        verify(() => store.save(any(), any())).called(1);
      },
    );

    test("a wrong code shows identity's reason and stores nothing", () async {
      when(() => api.verifyTwoFactor(any())).thenThrow(
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
  });

  group('login of an account that cannot drive yet', () {
    test('a pending account is not approved and stores nothing', () async {
      when(() => api.login(any())).thenAnswer((_) async => sessionJson);
      when(() => fleet.check(any())).thenAnswer(
        (_) async => const Err<DriverProfile>(PendingApprovalFailure()),
      );

      expect(failureOf(await login()), isA<PendingApprovalFailure>());
      verifyNever(() => store.save(any(), any()));
    });

    test('an account with no vehicle is an unfinished registration', () async {
      when(() => api.login(any())).thenAnswer((_) async => sessionJson);
      when(() => fleet.check(any())).thenAnswer(
        (_) async => const Err<DriverProfile>(RegistrationIncompleteFailure()),
      );

      expect(failureOf(await login()), isA<RegistrationIncompleteFailure>());
      verifyNever(() => store.save(any(), any()));
    });
  });

  group('register', () {
    test('is one call, and this app is no longer the coordinator', () async {
      when(
        () => api.registerCourier(any()),
      ).thenAnswer((_) async => registeredOk);

      final Result<DriverSession> res = await register();

      expect(res, isA<Ok<DriverSession>>());
      verify(() => api.registerCourier(any())).called(1);
      verifyNever(() => api.login(any()));
      verifyNever(() => fleet.check(any()));
    });

    test(
      'keeps the driver signed in, so the waiting screen needs no second password',
      () async {
        final DateTime now = DateTime.utc(2026, 1, 1);
        when(
          () => api.registerCourier(any()),
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
        () => api.registerCourier(any()),
      ).thenAnswer((_) async => registeredOk);

      await register();

      final RegisterCourierRequest sent =
          verify(() => api.registerCourier(captureAny())).captured.single
              as RegisterCourierRequest;
      expect(sent.fullName, 'Budi Santoso');
      expect(sent.phoneNumber, '081200000000');
      expect(sent.vehiclePlate, 'B 1234 KIN');
      expect(sent.capacityKg, 150);
    });

    test('409 carries the reason the server gave', () async {
      when(() => api.registerCourier(any())).thenThrow(
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
        when(() => api.registerCourier(any())).thenThrow(
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
      when(() => api.registerCourier(any())).thenThrow(
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
      when(() => api.registerCourier(any())).thenThrow(
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
      when(() => api.registerCourier(any())).thenThrow(dioWith(503));

      expect(failureOf(await register()).message, contains('again'));
    });

    test('stores nothing when registration fails', () async {
      when(() => api.registerCourier(any())).thenThrow(dioWith(409));

      await register();

      verifyNever(() => store.save(any(), any()));
    });
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
