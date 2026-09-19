import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/connection_repository.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/repositories/telemetry_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockConn extends Mock implements ConnectionRepository {}

class _MockOrders extends Mock implements OrderRepository {}

class _MockTele extends Mock implements TelemetryRepository {}

class _MockSession extends Mock implements SessionRepository {}

Order _order(int id) => new Order(
  id: new OrderId(id),
  status: OrderStatus.assigned,
  weightKg: 1,
  pickup: const LatLng(latitude: 1, longitude: 2),
  dropoff: const LatLng(latitude: 3, longitude: 4),
  assignedAt: DateTime.utc(2026),
);

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockConn conn;
  late _MockOrders orders;
  late _MockTele tele;
  late _MockSession session;
  late AppRouterState router;

  late StreamController<ConnectionStatus> statusCtrl;
  late StreamController<TelemetryPing> pingCtrl;
  late StreamController<Order?> orderCtrl;
  late StreamController<void> expiredCtrl;

  setUpAll(() {
    registerFallbackValue(
      const DriverSession(driverId: DriverId(0), token: '', refreshToken: 'refresh-token'),
    );
  });

  setUp(() {
    conn = new _MockConn();
    orders = new _MockOrders();
    tele = new _MockTele();
    session = new _MockSession();
    router = new AppRouterState();

    statusCtrl = StreamController<ConnectionStatus>.broadcast();
    pingCtrl = StreamController<TelemetryPing>.broadcast();
    orderCtrl = StreamController<Order?>.broadcast();
    expiredCtrl = StreamController<void>.broadcast();

    when(() => conn.statusStream).thenAnswer((_) => statusCtrl.stream);
    when(() => tele.sent).thenAnswer((_) => pingCtrl.stream);
    when(() => orders.watchActiveOrder()).thenAnswer((_) => orderCtrl.stream);
    when(() => conn.sessionExpired).thenAnswer((_) => expiredCtrl.stream);
    when(() => session.currentSession()).thenAnswer(
      (_) async => const DriverSession(driverId: DriverId(1), token: 't', refreshToken: 'refresh-token'),
    );
    when(() => conn.connect(any())).thenAnswer((_) async {});
    when(
      () => conn.setStatus(any()),
    ).thenAnswer((_) async => const Ok<Unit>(Unit.unit));
    when(() => conn.disconnect()).thenAnswer((_) async {});
    when(() => tele.start()).thenAnswer((_) async => const Ok<Unit>(Unit.unit));
    when(() => tele.stop()).thenAnswer((_) async {});
    when(() => session.logout()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await statusCtrl.close();
    await pingCtrl.close();
    await orderCtrl.close();
    await expiredCtrl.close();
  });

  TrackingViewModel build() =>
      new TrackingViewModel(router, conn, orders, tele, session);

  test('connected status yields TrackingOnline', () async {
    final TrackingViewModel vm = build();
    await pump();
    statusCtrl.add(ConnectionStatus.connected);
    await pump();
    expect(vm.state, isA<TrackingOnline>());
  });

  test('order event pushes OrderRoute once (dedup)', () async {
    build();
    await pump();
    orderCtrl.add(_order(5));
    await pump();
    orderCtrl.add(_order(5));
    await pump();
    expect(router.stack.whereType<OrderRoute>().length, 1);
  });

  test('toggleDuty online starts telemetry and sets status', () async {
    final TrackingViewModel vm = build();
    await pump();
    statusCtrl.add(ConnectionStatus.connected);
    await pump();
    await vm.toggleDuty();
    verify(() => tele.start()).called(1);
    verify(() => conn.setStatus('online')).called(1);
    expect((vm.state as TrackingOnline).onDuty, isTrue);
  });

  test('busy reflects an active order', () async {
    final TrackingViewModel vm = build();
    await pump();
    statusCtrl.add(ConnectionStatus.connected);
    await pump();

    orderCtrl.add(_order(5));
    await pump();
    expect((vm.state as TrackingOnline).busy, isTrue);

    orderCtrl.add(null);
    await pump();
    expect((vm.state as TrackingOnline).busy, isFalse);
  });

  test('toggleDuty blocked on permission failure', () async {
    when(
      () => tele.start(),
    ).thenAnswer((_) async => const Err<Unit>(PermissionFailure()));
    final TrackingViewModel vm = build();
    await pump();
    statusCtrl.add(ConnectionStatus.connected);
    await pump();
    await vm.toggleDuty();
    expect((vm.state as TrackingOnline).permissionBlocked, isTrue);
  });

  test('sessionExpired routes to Login', () async {
    build();
    await pump();
    expiredCtrl.add(null);
    await pump();
    await pump();
    expect(router.stack.last, isA<LoginRoute>());
  });
}
