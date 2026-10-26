import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/repositories/duty_repository.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConn extends Mock implements ConnectionRepository {}

class _MockOrders extends Mock implements OrderRepository {}

class _MockDuty extends Mock implements DutyRepository {}

class _MockSession extends Mock implements SessionRepository {}

Order _order(int id) => new Order(
  id: new OrderId(id),
  status: OrderStatus.assigned,
  weightKg: 1,
  pickup: const LatLng(latitude: 1, longitude: 2),
  dropoff: const LatLng(latitude: 3, longitude: 4),
  assignedAt: DateTime.utc(2026),
);

Future<void> pump() async {
  for (int i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _MockConn conn;
  late _MockOrders orders;
  late _MockDuty duty;
  late _MockSession session;
  late AppRouterState router;
  late bool onDuty;

  late StreamController<ConnectionStatus> statusCtrl;
  late StreamController<TelemetryPing> pingCtrl;
  late StreamController<DriverAvailability> availabilityCtrl;
  late StreamController<Failure> problemCtrl;
  late StreamController<JobUpdate> orderCtrl;
  late StreamController<SessionEnd> endCtrl;

  setUpAll(() {
    registerFallbackValue(
      const DriverSession(
        driverId: DriverId(0),
        token: '',
        refreshToken: 'refresh-token',
      ),
    );
  });

  setUp(() {
    conn = new _MockConn();
    orders = new _MockOrders();
    duty = new _MockDuty();
    session = new _MockSession();
    router = new AppRouterState();
    onDuty = false;

    statusCtrl = StreamController<ConnectionStatus>.broadcast();
    pingCtrl = StreamController<TelemetryPing>.broadcast();
    availabilityCtrl = StreamController<DriverAvailability>.broadcast();
    problemCtrl = StreamController<Failure>.broadcast();
    orderCtrl = StreamController<JobUpdate>.broadcast();
    endCtrl = StreamController<SessionEnd>.broadcast();

    when(() => conn.statusStream).thenAnswer((_) => statusCtrl.stream);
    when(() => conn.sessionEnded).thenAnswer((_) => endCtrl.stream);
    when(() => duty.sent).thenAnswer((_) => pingCtrl.stream);
    when(() => duty.availability).thenAnswer((_) => availabilityCtrl.stream);
    when(() => duty.problems).thenAnswer((_) => problemCtrl.stream);
    when(() => duty.onDuty).thenAnswer((_) => onDuty);
    when(() => orders.watchJobs()).thenAnswer((_) => orderCtrl.stream);
    when(() => session.currentSession()).thenAnswer(
      (_) async => const DriverSession(
        driverId: DriverId(1),
        token: 't',
        refreshToken: 'refresh-token',
      ),
    );
    when(() => conn.connect(any())).thenAnswer((_) async {});
    when(() => conn.disconnect()).thenAnswer((_) async {});
    when(() => duty.goOnDuty()).thenAnswer((_) async {
      onDuty = true;

      return const Ok<DriverAvailability>(DriverAvailability.online);
    });
    when(() => duty.goOffDuty()).thenAnswer((_) async {
      onDuty = false;

      return const Ok<DriverAvailability>(DriverAvailability.offline);
    });
    when(() => session.logout()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await statusCtrl.close();
    await pingCtrl.close();
    await availabilityCtrl.close();
    await problemCtrl.close();
    await orderCtrl.close();
    await endCtrl.close();
  });

  TrackingViewModel build() =>
      new TrackingViewModel(router, conn, orders, duty, session);

  Future<TrackingViewModel> connected() async {
    final TrackingViewModel vm = build();
    await pump();
    statusCtrl.add(ConnectionStatus.connected);
    await pump();

    return vm;
  }

  test('connected status yields TrackingOnline', () async {
    final TrackingViewModel vm = await connected();

    expect(vm.state, isA<TrackingOnline>());
  });

  test('order event pushes OrderRoute once (dedup)', () async {
    build();
    await pump();
    orderCtrl.add(new JobActive(_order(5)));
    await pump();
    orderCtrl.add(new JobActive(_order(5)));
    await pump();
    expect(router.stack.whereType<OrderRoute>().length, 1);
  });

  test('going on duty shows the availability the server decided', () async {
    when(() => duty.goOnDuty()).thenAnswer((_) async {
      onDuty = true;

      return const Ok<DriverAvailability>(DriverAvailability.busy);
    });
    final TrackingViewModel vm = await connected();

    await vm.toggleDuty();

    final TrackingOnline state = vm.state as TrackingOnline;
    expect(state.onDuty, isTrue);
    expect(state.availability, DriverAvailability.busy);
  });

  test('going off duty asks the duty repository', () async {
    final TrackingViewModel vm = await connected();
    await vm.toggleDuty();

    await vm.toggleDuty();

    verify(() => duty.goOffDuty()).called(1);
    expect(
      (vm.state as TrackingOnline).availability,
      DriverAvailability.offline,
    );
  });

  test('an active job shows the courier busy while on duty', () async {
    final TrackingViewModel vm = await connected();
    await vm.toggleDuty();

    orderCtrl.add(new JobActive(_order(5)));
    await pump();
    expect((vm.state as TrackingOnline).availability, DriverAvailability.busy);

    orderCtrl.add(const JobNone());
    await pump();
    expect(
      (vm.state as TrackingOnline).availability,
      DriverAvailability.online,
    );
  });

  test('a cancelled job frees the courier and opens nothing', () async {
    final TrackingViewModel vm = await connected();
    await vm.toggleDuty();
    orderCtrl.add(new JobActive(_order(5)));
    await pump();

    orderCtrl.add(const JobCancelled(OrderId(5)));
    await pump();

    expect(
      (vm.state as TrackingOnline).availability,
      DriverAvailability.online,
    );
    expect(router.stack.whereType<OrderRoute>(), hasLength(1));
  });

  test('toggleDuty blocked on permission failure', () async {
    when(() => duty.goOnDuty()).thenAnswer(
      (_) async => const Err<DriverAvailability>(PermissionFailure()),
    );
    final TrackingViewModel vm = await connected();

    await vm.toggleDuty();

    expect((vm.state as TrackingOnline).permissionBlocked, isTrue);
  });

  test('a telemetry problem is shown to the courier', () async {
    final TrackingViewModel vm = await connected();

    problemCtrl.add(const ChannelFailure('invalid_telemetry'));
    await pump();

    expect((vm.state as TrackingOnline).lastMessage, contains('date and time'));
  });

  test(
    'a session that ended (a refresh refused after a second-factor change) signs out cleanly',
    () async {
      build();
      await pump();

      endCtrl.add(const SessionSignedOut());
      await pump();

      verifyInOrder(<void Function()>[
        () => duty.goOffDuty(),
        () => conn.disconnect(),
        () => session.logout(),
      ]);
      expect(router.stack.single, isA<LoginRoute>());
    },
  );

  test(
    'a build identity no longer accepts asks for an update and keeps the session',
    () async {
      build();
      await pump();

      endCtrl.add(const SessionUpdateRequired());
      await pump();

      expect(router.stack.single, isA<UpdateRequiredRoute>());
      verify(() => duty.goOffDuty()).called(1);
      verify(() => conn.disconnect()).called(1);
      verifyNever(() => session.logout());
    },
  );

  test(
    'an account not approved goes to the waiting screen and keeps the session',
    () async {
      build();
      await pump();

      endCtrl.add(const SessionNotApproved());
      await pump();

      expect(router.stack.single, isA<PendingApprovalRoute>());
      verify(() => conn.disconnect()).called(1);
      verifyNever(() => session.logout());
    },
  );

  test(
    'logout goes off duty, closes the socket, then ends the session',
    () async {
      final TrackingViewModel vm = await connected();

      await vm.logout();

      verifyInOrder(<void Function()>[
        () => duty.goOffDuty(),
        () => conn.disconnect(),
        () => session.logout(),
      ]);
      expect(router.stack.single, isA<LoginRoute>());
    },
  );
}
