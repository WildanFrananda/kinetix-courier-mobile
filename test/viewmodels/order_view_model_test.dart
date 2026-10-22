import 'dart:async';

import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/maps/maps_launcher.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/order_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrders extends Mock implements OrderRepository {}

class _MockMaps extends Mock implements MapsLauncher {}

Order _order(OrderStatus status) => new Order(
  id: const OrderId(5),
  status: status,
  weightKg: 1,
  pickup: const LatLng(latitude: 1, longitude: 2),
  dropoff: const LatLng(latitude: 3, longitude: 4),
  assignedAt: DateTime.utc(2026),
);

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockOrders orders;
  late _MockMaps maps;
  late AppRouterState router;
  late OrderViewModel sut;
  late StreamController<Order?> orderCtrl;
  late StreamController<OrderId> unassignedCtrl;

  setUpAll(() => registerFallbackValue(const OrderId(0)));

  setUp(() {
    orders = new _MockOrders();
    maps = new _MockMaps();
    router = new AppRouterState();
    orderCtrl = StreamController<Order?>.broadcast();
    unassignedCtrl = StreamController<OrderId>.broadcast();
    when(() => orders.watchActiveOrder()).thenAnswer((_) => orderCtrl.stream);
    when(
      () => orders.watchUnassigned(),
    ).thenAnswer((_) => unassignedCtrl.stream);
    when(
      () => orders.pickup(any()),
    ).thenAnswer((_) async => const Ok<Unit>(Unit.unit));
    when(
      () => orders.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    ).thenAnswer((_) async => const Ok<Unit>(Unit.unit));

    when(() => orders.attachPodPhoto(any(), any())).thenAnswer(
      (_) async =>
          const Ok<String>('https://storage.test/kinetix-pod/pod/5/a.jpg'),
    );

    sut = new OrderViewModel(router, orders, maps);
  });

  tearDown(() async {
    await orderCtrl.close();
    await unassignedCtrl.close();
  });

  const String signature = 'data:image/png;base64,AAAA';

  test('bind seeds OrderShowing', () {
    sut.bind(_order(OrderStatus.assigned));
    expect(sut.state, isA<OrderShowing>());
    expect((sut.state as OrderShowing).order.id.value, 5);
  });

  test('pickup ok clears error', () async {
    sut.bind(_order(OrderStatus.assigned));
    await sut.pickup();
    final OrderShowing state = sut.state as OrderShowing;
    expect(state.submitting, isFalse);
    expect(state.error, isNull);
    verify(() => orders.pickup(const OrderId(5))).called(1);
  });

  test('pickup failure surfaces error', () async {
    when(() => orders.pickup(any())).thenAnswer(
      (_) async => const Err<Unit>(ChannelFailure('invalid_transition')),
    );
    sut.bind(_order(OrderStatus.assigned));
    await sut.pickup();
    expect((sut.state as OrderShowing).error, isA<ChannelFailure>());
  });

  test('delivered ok pops the route', () async {
    router.push(new OrderRoute(order: _order(OrderStatus.pickedUp)));
    sut.bind(_order(OrderStatus.pickedUp));
    await sut.attachPhoto('/tmp/photo.jpg');
    sut.setPodSignature(signature);
    await sut.delivered();
    expect(router.stack.last, isA<SplashRoute>());
  });

  test('a delivery cannot be marked before its photo is uploaded', () async {
    sut.bind(_order(OrderStatus.pickedUp));

    expect(sut.canDeliver, isFalse);
    await sut.delivered();

    verifyNever(
      () => orders.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    );
  });

  test('the uploaded photo is what the delivery names', () async {
    sut.bind(_order(OrderStatus.pickedUp));

    await sut.attachPhoto('/tmp/photo.jpg');
    sut.setPodSignature(signature);

    expect(sut.canDeliver, isTrue);
    await sut.delivered();
    verify(
      () => orders.delivered(
        const OrderId(5),
        podPhotoUrl: 'https://storage.test/kinetix-pod/pod/5/a.jpg',
        podSignature: signature,
      ),
    ).called(1);
  });

  test(
    'a photo that could not be uploaded leaves the delivery locked',
    () async {
      when(
        () => orders.attachPodPhoto(any(), any()),
      ).thenAnswer((_) async => const Err<String>(PodPhotoFailure()));
      sut.bind(_order(OrderStatus.pickedUp));

      await sut.attachPhoto('/tmp/photo.jpg');

      expect(sut.canDeliver, isFalse);
      expect((sut.state as OrderShowing).error, isA<PodPhotoFailure>());
    },
  );

  test('server cancel switches to OrderCancelled', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();
    orderCtrl.add(null);
    await pump();
    expect(sut.state, isA<OrderCancelled>());
  });

  test('a delivery cannot be marked without the signature', () async {
    sut.bind(_order(OrderStatus.pickedUp));

    await sut.attachPhoto('/tmp/photo.jpg');

    expect(sut.canDeliver, isFalse);
    await sut.delivered();
    verifyNever(
      () => orders.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    );
  });

  test('a job dispatch takes off the courier says so', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();

    unassignedCtrl.add(const OrderId(5));
    orderCtrl.add(null);
    await pump();

    expect(sut.state, isA<OrderUnassigned>());
  });

  test('another job taken off the courier changes nothing here', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();

    unassignedCtrl.add(const OrderId(9));
    await pump();

    expect(sut.state, isA<OrderShowing>());
  });

  test('an update to this job is shown', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();

    orderCtrl.add(_order(OrderStatus.pickedUp));
    await pump();

    expect((sut.state as OrderShowing).order.status, OrderStatus.pickedUp);
  });
}
