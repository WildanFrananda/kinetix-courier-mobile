import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/ui/screens/order_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/order_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements OrderViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

Order _order(OrderStatus status) => new Order(
  id: const OrderId(5),
  status: status,
  weightKg: 1,
  pickup: const LatLng(latitude: 1, longitude: 2),
  dropoff: const LatLng(latitude: 3, longitude: 4),
  assignedAt: DateTime.utc(2026),
);

Future<void> _pump(WidgetTester tester, OrderViewModel vm, Order order) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: ChangeNotifierProvider<OrderViewModel>.value(
        value: vm,
        child: OrderScreen(order: order),
      ),
    ),
  );
}

void main() {
  late _MockVm vm;

  setUpAll(() {
    registerFallbackValue(_order(OrderStatus.assigned));
  });

  setUp(() {
    vm = new _MockVm();
    when(() => vm.bind(any())).thenAnswer((_) async {});
    when(() => vm.pickup()).thenAnswer((_) async {});
    when(() => vm.delivered()).thenAnswer((_) async {});
    when(() => vm.back()).thenAnswer((_) async {});
    when(() => vm.podPhotoUrl).thenReturn(null);
    when(() => vm.podSignature).thenReturn(null);
    when(() => vm.photoUploading).thenReturn(false);
    when(() => vm.canDeliver).thenReturn(false);
  });

  testWidgets('assigned enables pickup, hides delivered button', (
    WidgetTester tester,
  ) async {
    final Order order = _order(OrderStatus.assigned);
    when(() => vm.state).thenReturn(new OrderShowing(order));
    await _pump(tester, vm, order);

    final ElevatedButton pickupBtn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Mark as Picked Up'),
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(pickupBtn.onPressed, isNotNull);
    expect(find.text('Mark as Delivered'), findsNothing);

    await tester.tap(find.text('Mark as Picked Up'));
    verify(() => vm.pickup()).called(1);
  });

  testWidgets('cancelled shows message and back button', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(const OrderCancelled());
    await _pump(tester, vm, _order(OrderStatus.assigned));
    expect(find.text('Order cancelled'), findsOneWidget);
    await tester.tap(find.text('Back'));
    verify(() => vm.back()).called(1);
  });

  testWidgets('a job taken off the courier says so', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(const OrderUnassigned());
    await _pump(tester, vm, _order(OrderStatus.assigned));

    expect(find.text('Dispatch has taken this job off you'), findsOneWidget);
  });

  testWidgets('a job that ended while away is not called cancelled', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(const OrderNoLongerActive());
    await _pump(tester, vm, _order(OrderStatus.assigned));

    expect(find.text('This job is no longer active for you'), findsOneWidget);
    expect(find.text('Order cancelled'), findsNothing);
  });

  testWidgets(
    'a picked-up job cannot be delivered until photo and signature exist',
    (WidgetTester tester) async {
      final Order order = _order(OrderStatus.pickedUp);
      when(() => vm.state).thenReturn(new OrderShowing(order));
      await _pump(tester, vm, order);

      final ElevatedButton deliverBtn = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Mark as Delivered'),
          matching: find.byType(ElevatedButton),
        ),
      );

      expect(deliverBtn.onPressed, isNull);
      expect(
        find.textContaining('signature are both required'),
        findsOneWidget,
      );
    },
  );
}
