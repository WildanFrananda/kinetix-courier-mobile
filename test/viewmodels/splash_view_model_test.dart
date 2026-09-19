import 'package:fake_async/fake_async.dart';
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

  setUp(() => session = new _MockSession());

  test('no stored session routes to Login', () {
    fakeAsync((async) {
      when(() => session.currentSession()).thenAnswer((_) async => null);
      final AppRouterState router = new AppRouterState();
      new SplashViewModel(router, session);
      async.elapse(const Duration(milliseconds: 500));
      expect(router.stack.last, isA<LoginRoute>());
    });
  });

  test('stored session routes to Tracking', () {
    fakeAsync((async) {
      when(() => session.currentSession()).thenAnswer(
        (_) async => const DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'refresh-token'),
      );
      final AppRouterState router = new AppRouterState();
      new SplashViewModel(router, session);
      async.elapse(const Duration(milliseconds: 500));
      expect(router.stack.last, isA<TrackingRoute>());
    });
  });
}
