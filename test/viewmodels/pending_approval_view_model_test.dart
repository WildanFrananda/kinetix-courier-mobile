import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/approval_check_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  test(
    'backToLogin signs out, then replaces the stack with LoginRoute',
    () async {
      final _MockSession session = new _MockSession();
      when(session.logout).thenAnswer((_) async {});
      final AppRouterState router = new AppRouterState()
        ..push(const PendingApprovalRoute());

      await new PendingApprovalViewModel(router, session).backToLogin();

      verify(session.logout).called(1);
      expect(router.stack.last, isA<LoginRoute>());
      expect(router.stack.length, 1);
    },
  );
  group('check again', () {
    late _MockSession session;
    late AppRouterState router;
    late PendingApprovalViewModel sut;

    const DriverProfile approved = DriverProfile(
      id: DriverId(9),
      vehiclePlate: 'B 1 ABC',
      capacityKg: 100,
      status: 'offline',
      active: true,
    );

    setUp(() {
      session = new _MockSession();
      when(session.logout).thenAnswer((_) async {});
      router = new AppRouterState()..replaceAll(const PendingApprovalRoute());
      sut = new PendingApprovalViewModel(router, session);
    });

    test('an approved courier goes straight to tracking', () async {
      when(
        session.standing,
      ).thenAnswer((_) async => const Ok<DriverProfile>(approved));

      await sut.checkAgain();

      expect(router.stack.single, isA<TrackingRoute>());
      verifyNever(session.logout);
    });

    test('a courier still waiting is told so and stays', () async {
      when(session.standing).thenAnswer(
        (_) async => const Err<DriverProfile>(PendingApprovalFailure()),
      );

      await sut.checkAgain();

      expect(sut.state, isA<ApprovalStillPending>());
      expect(router.stack.single, isA<PendingApprovalRoute>());
    });

    test(
      'a fleet that cannot be asked keeps the courier waiting, with why',
      () async {
        when(session.standing).thenAnswer(
          (_) async => const Err<DriverProfile>(
            ServiceUnavailableFailure('The fleet could not be reached.'),
          ),
        );

        await sut.checkAgain();

        expect(
          (sut.state as ApprovalCheckFailed).message,
          'The fleet could not be reached.',
        );
        verifyNever(session.logout);
      },
    );

    test(
      'a build identity does not accept asks for an update, and keeps the session',
      () async {
        when(session.standing).thenAnswer(
          (_) async => const Err<DriverProfile>(AppUpdateRequiredFailure()),
        );

        await sut.checkAgain();

        expect(router.stack.single, isA<UpdateRequiredRoute>());
        verifyNever(session.logout);
      },
    );

    test('a refused session signs out to the login', () async {
      when(
        session.standing,
      ).thenAnswer((_) async => const Err<DriverProfile>(AuthFailure()));

      await sut.checkAgain();

      verify(session.logout).called(1);
      expect(router.stack.single, isA<LoginRoute>());
    });
  });
}
