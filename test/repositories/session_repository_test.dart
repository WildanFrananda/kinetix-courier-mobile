import 'package:clock/clock.dart';
import 'package:dio/dio.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository_impl.dart';
import 'package:fleet_pulse_mobile/services/auth/driver_api.dart';
import 'package:fleet_pulse_mobile/services/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApi extends Mock implements DriverApi {}

class _MockStore extends Mock implements TokenStore {}

void main() {
  late _MockApi api;
  late _MockStore store;
  late SessionRepositoryImpl sut;

  const AuthenticatedAccount account = AuthenticatedAccount(
    id: 7,
    email: 'driver@kinetix.test',
    role: 'courier',
    principalId: '11111111-2222-3333-4444-555555555555',
  );

  const SessionResponse authOk = SessionResponse(
    accessToken: 'tok',
    refreshToken: 'refresh',
    expiresIn: 604800,
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

  const DriverProfileEnvelope profileOk = DriverProfileEnvelope(
    data: DriverProfile(
      id: DriverId(9),
      vehiclePlate: 'B 1 ABC',
      capacityKg: 100,
      status: 'available',
      active: true,
    ),
  );

  setUpAll(() {
    registerFallbackValue(const LoginRequest(email: '', password: ''));
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
    sut = new SessionRepositoryImpl(api, store);
    when(() => store.save(any(), any())).thenAnswer((_) async {});
  });

  DioException dioWith(int code, [Map<String, dynamic>? body]) =>
      new DioException(
        requestOptions: new RequestOptions(path: '/couriers/register'),
        response: new Response<Map<String, dynamic>>(
          requestOptions: new RequestOptions(path: '/couriers/register'),
          statusCode: code,
          data: body,
        ),
      );

  Future<Result<DriverSession>> login() =>
      sut.login(email: 'driver@kinetix.test', password: 'supersecret1234');

  Future<Result<DriverSession>> register() => sut.register(
    email: 'driver@kinetix.test',
    password: 'supersecret1234',
    name: 'Budi Santoso',
    phone: '081200000000',
    vehiclePlate: 'B 1234 KIN',
    capacityKg: 150,
  );

  group('login', () {
    test(
      'asks the fleet who it is and stores both halves of the session',
      () async {
        final DateTime now = DateTime.utc(2026, 1, 1);
        when(() => api.login(any())).thenAnswer((_) async => authOk);
        when(() => api.me(any())).thenAnswer((_) async => profileOk);

        final Result<DriverSession> res = await withClock(
          Clock.fixed(now),
          login,
        );

        expect(res, isA<Ok<DriverSession>>());
        final List<dynamic> captured = verify(
          () => store.save(captureAny(), captureAny()),
        ).captured;
        final DriverSession saved = captured[0] as DriverSession;
        expect(saved.token, 'tok');
        expect(saved.refreshToken, 'refresh');
        expect(saved.driverId, const DriverId(9));
        expect(
          captured[1] as DateTime,
          now.add(const Duration(seconds: 604800)),
        );
      },
    );

    test(
      'authorises the fleet call with the token identity just issued',
      () async {
        when(() => api.login(any())).thenAnswer((_) async => authOk);
        when(() => api.me(any())).thenAnswer((_) async => profileOk);

        await login();

        verify(() => api.me('Bearer tok')).called(1);
      },
    );

    test('401 maps to AuthFailure', () async {
      when(() => api.login(any())).thenThrow(dioWith(401));
      expect((await login() as Err<DriverSession>).failure, isA<AuthFailure>());
    });

    test('unexpected error maps to NetworkFailure', () async {
      when(() => api.login(any())).thenThrow(new Exception('boom'));
      expect(
        (await login() as Err<DriverSession>).failure,
        isA<NetworkFailure>(),
      );
    });
  });

  group('login of an account that cannot drive yet', () {
    test('403 means an administrator has not approved it', () async {
      when(() => api.login(any())).thenAnswer((_) async => authOk);
      when(() => api.me(any())).thenThrow(dioWith(403));

      expect(
        (await login() as Err<DriverSession>).failure,
        isA<PendingApprovalFailure>(),
      );
    });

    test('404 means no vehicle was ever filed', () async {
      when(() => api.login(any())).thenAnswer((_) async => authOk);
      when(() => api.me(any())).thenThrow(dioWith(404));

      expect(
        (await login() as Err<DriverSession>).failure,
        isA<RegistrationIncompleteFailure>(),
      );
    });

    test('the two are not the same failure', () async {
      when(() => api.login(any())).thenAnswer((_) async => authOk);

      when(() => api.me(any())).thenThrow(dioWith(403));
      final Failure waiting = (await login() as Err<DriverSession>).failure;

      when(() => api.me(any())).thenThrow(dioWith(404));
      final Failure unfinished = (await login() as Err<DriverSession>).failure;

      expect(waiting.runtimeType, isNot(unfinished.runtimeType));
    });

    for (final int code in <int>[403, 404]) {
      test('$code stores nothing', () async {
        when(() => api.login(any())).thenAnswer((_) async => authOk);
        when(() => api.me(any())).thenThrow(dioWith(code));

        await login();

        verifyNever(() => store.save(any(), any()));
      });
    }
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
      verifyNever(() => api.me(any()));
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

      final Failure f = (await register() as Err<DriverSession>).failure;
      expect(f, isA<AuthFailure>());
      expect(f.message, contains('already exists'));
    });

    test('400 carries the fleet refusal the applicant can correct', () async {
      when(() => api.registerCourier(any())).thenThrow(
        dioWith(400, <String, dynamic>{
          'error': 'NO_CAPACITY',
          'message': 'capacity_kg must be greater than zero',
        }),
      );

      final Failure f = (await register() as Err<DriverSession>).failure;
      expect(f, isA<ChannelFailure>());
      expect(f.message, contains('capacity_kg'));
    });

    test('503 tells the driver to submit the same details again', () async {
      when(() => api.registerCourier(any())).thenThrow(
        dioWith(503, <String, dynamic>{
          'error': 'FLEET_UNAVAILABLE',
          'message':
              'Your account was created. Submit the same details again to finish.',
        }),
      );

      final Failure f = (await register() as Err<DriverSession>).failure;
      expect(f, isA<ChannelFailure>());
      expect(f.message, contains('again'));
    });

    test('503 with no body still says something actionable', () async {
      when(() => api.registerCourier(any())).thenThrow(dioWith(503));

      final Failure f = (await register() as Err<DriverSession>).failure;
      expect(f.message, contains('again'));
    });

    test('stores nothing when registration fails', () async {
      when(() => api.registerCourier(any())).thenThrow(dioWith(409));

      await register();

      verifyNever(() => store.save(any(), any()));
    });
  });
}
