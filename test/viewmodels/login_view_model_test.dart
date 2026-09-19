import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  late _MockSession session;
  late AppRouterState router;
  late LoginViewModel sut;

  setUp(() {
    session = new _MockSession();
    router = new AppRouterState();
    sut = new LoginViewModel(router, session);
  });

  test('empty fields set an error and skip login', () async {
    await sut.submit();
    expect(sut.error, isNotNull);
    verifyNever(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('successful login routes to Tracking', () async {
    when(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Ok<DriverSession>(
        DriverSession(
          driverId: DriverId(1),
          token: 't',
          refreshToken: 'refresh-token',
        ),
      ),
    );
    sut
      ..setEmail('driver@kinetix.test')
      ..setPassword('secret');
    await sut.submit();
    expect(router.stack.last, isA<TrackingRoute>());
  });

  test('failed login surfaces the message', () async {
    when(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Err<DriverSession>(AuthFailure()));
    sut
      ..setEmail('driver@kinetix.test')
      ..setPassword('wrong');
    await sut.submit();
    expect(sut.error, 'session expired');
    expect(router.stack.last, isA<SplashRoute>());
  });

  test('an incomplete registration routes to the register form', () async {
    when(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Err<DriverSession>(RegistrationIncompleteFailure()),
    );
    sut
      ..setEmail('driver@kinetix.test')
      ..setPassword('secret');
    await sut.submit();
    expect(router.stack.last, isA<RegisterRoute>());
    expect(sut.error, contains('vehicle'));
  });

  test('pending approval routes to PendingApprovalRoute', () async {
    when(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const Err<DriverSession>(PendingApprovalFailure()),
    );
    sut
      ..setEmail('driver@kinetix.test')
      ..setPassword('secret');
    await sut.submit();
    expect(router.stack.last, isA<PendingApprovalRoute>());
  });
}
