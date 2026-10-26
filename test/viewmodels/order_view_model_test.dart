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
  late StreamController<JobUpdate> jobCtrl;

  setUpAll(() => registerFallbackValue(const OrderId(0)));

  setUp(() {
    orders = new _MockOrders();
    maps = new _MockMaps();
    router = new AppRouterState();
    jobCtrl = StreamController<JobUpdate>.broadcast();
    when(() => orders.watchJobs()).thenAnswer((_) => jobCtrl.stream);
    when(
      () => orders.proofDraft(any()),
    ).thenAnswer((_) async => const DeliveryProofDraft());
    when(() => orders.keepSignature(any(), any())).thenAnswer((_) async {});
    when(() => orders.discardProofDraft(any())).thenAnswer((_) async {});
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
    await jobCtrl.close();
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
    await sut.setPodSignature(signature);
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
    await sut.setPodSignature(signature);

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
    jobCtrl.add(const JobCancelled(OrderId(5)));
    await pump();
    expect(sut.state, isA<OrderCancelled>());
    verify(() => orders.discardProofDraft(const OrderId(5))).called(1);
  });

  test('the cancellation of another job changes nothing here', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();
    jobCtrl.add(const JobCancelled(OrderId(9)));
    await pump();
    expect(sut.state, isA<OrderShowing>());
  });

  test(
    'an active_order for another job never reads as a cancellation',
    () async {
      sut.bind(_order(OrderStatus.assigned));
      await pump();

      jobCtrl.add(
        new JobActive(
          new Order(
            id: const OrderId(9),
            status: OrderStatus.assigned,
            weightKg: 2,
            pickup: const LatLng(latitude: 1, longitude: 2),
            dropoff: const LatLng(latitude: 3, longitude: 4),
            assignedAt: DateTime.utc(2026),
          ),
        ),
      );
      await pump();

      expect((sut.state as OrderShowing).order.id, const OrderId(5));
    },
  );

  test(
    'no active job at all says the job is no longer active, not cancelled',
    () async {
      sut.bind(_order(OrderStatus.assigned));
      await pump();

      jobCtrl.add(const JobNone());
      await pump();

      expect(sut.state, isA<OrderNoLongerActive>());
    },
  );

  test(
    'a proof taken before the app restarted is restored for the job',
    () async {
      when(() => orders.proofDraft(const OrderId(5))).thenAnswer(
        (_) async => const DeliveryProofDraft(
          photoUrl: 'https://storage.test/kinetix-pod/pod/5/a.jpg',
          signature: signature,
        ),
      );

      sut.bind(_order(OrderStatus.pickedUp));
      await pump();

      expect(sut.podPhotoUrl, 'https://storage.test/kinetix-pod/pod/5/a.jpg');
      expect(sut.podSignature, signature);
      expect(sut.canDeliver, isTrue);
    },
  );

  test('a signature is kept for the job as soon as it is drawn', () async {
    sut.bind(_order(OrderStatus.pickedUp));

    await sut.setPodSignature(signature);

    verify(() => orders.keepSignature(const OrderId(5), signature)).called(1);
  });

  test('a delivery answered after the screen closed touches nothing', () async {
    final Completer<Result<Unit>> answer = new Completer<Result<Unit>>();
    when(
      () => orders.delivered(
        any(),
        podPhotoUrl: any(named: 'podPhotoUrl'),
        podSignature: any(named: 'podSignature'),
      ),
    ).thenAnswer((_) => answer.future);
    router.push(new OrderRoute(order: _order(OrderStatus.pickedUp)));
    sut.bind(_order(OrderStatus.pickedUp));
    await sut.attachPhoto('/tmp/photo.jpg');
    await sut.setPodSignature(signature);

    final Future<void> delivering = sut.delivered();
    sut.dispose();
    answer.complete(const Err<Unit>(NetworkFailure()));
    await delivering;

    expect(router.stack.last, isA<OrderRoute>());
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

    jobCtrl
      ..add(const JobUnassigned(OrderId(5)))
      ..add(const JobNone());
    await pump();

    expect(sut.state, isA<OrderUnassigned>());
  });

  test('another job taken off the courier changes nothing here', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();

    jobCtrl.add(const JobUnassigned(OrderId(9)));
    await pump();

    expect(sut.state, isA<OrderShowing>());
  });

  test('an update to this job is shown', () async {
    sut.bind(_order(OrderStatus.assigned));
    await pump();

    jobCtrl.add(new JobActive(_order(OrderStatus.pickedUp)));
    await pump();

    expect((sut.state as OrderShowing).order.status, OrderStatus.pickedUp);
  });
}
