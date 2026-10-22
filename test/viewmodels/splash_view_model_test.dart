import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/splash_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  late _MockSession session;

  const DriverSession stored = DriverSession(
    driverId: DriverId(1),
    token: 't',
    refreshToken: 'refresh-token',
  );
  const DriverProfile approved = DriverProfile(
    id: DriverId(1),
    vehiclePlate: 'B 1 ABC',
    capacityKg: 100,
    status: 'offline',
    active: true,
  );

  setUp(() {
    session = new _MockSession();
    when(() => session.logout()).thenAnswer((_) async {});
  });

  AppRoute routeAfterSplash(Result<DriverProfile>? standing) {
    late AppRoute route;

    fakeAsync((FakeAsync async) {
      when(
        () => session.currentSession(),
      ).thenAnswer((_) async => standing == null ? null : stored);

      if (standing != null) {
        when(() => session.standing()).thenAnswer((_) async => standing);
      }

      final AppRouterState router = new AppRouterState();
      new SplashViewModel(router, session);
      async.elapse(const Duration(milliseconds: 500));
      route = router.stack.last;
    });

    return route;
  }

  test('no stored session routes to Login', () {
    expect(routeAfterSplash(null), isA<LoginRoute>());
  });

  test('an approved courier routes to Tracking', () {
    expect(
      routeAfterSplash(const Ok<DriverProfile>(approved)),
      isA<TrackingRoute>(),
    );
  });

  test(
    'a pending courier waits for approval instead of looping on the socket',
    () {
      expect(
        routeAfterSplash(const Err<DriverProfile>(PendingApprovalFailure())),
        isA<PendingApprovalRoute>(),
      );
    },
  );

  test('a session the fleet refuses is signed out', () {
    expect(
      routeAfterSplash(const Err<DriverProfile>(AuthFailure())),
      isA<LoginRoute>(),
    );
    verify(() => session.logout()).called(1);
  });

  test('a fleet that cannot be asked does not sign anyone out', () {
    expect(
      routeAfterSplash(const Err<DriverProfile>(NetworkFailure())),
      isA<TrackingRoute>(),
    );
    verifyNever(() => session.logout());
  });
}
