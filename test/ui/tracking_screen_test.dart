import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/state/tracking_state.dart';
import 'package:fleet_pulse_mobile/ui/screens/tracking_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements TrackingViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

Future<void> _pump(WidgetTester tester, TrackingViewModel vm) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: ChangeNotifierProvider<TrackingViewModel>.value(
        value: vm,
        child: const TrackingScreen(),
      ),
    ),
  );
}

void main() {
  late _MockVm vm;

  setUp(() {
    vm = new _MockVm();
    when(() => vm.logout()).thenAnswer((_) async {});
    when(() => vm.toggleDuty()).thenAnswer((_) async {});
    when(() => vm.openSettings()).thenAnswer((_) async {});
  });

  testWidgets('connecting shows a spinner', (WidgetTester tester) async {
    when(() => vm.state).thenReturn(const TrackingConnecting());
    await _pump(tester, vm);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('online shows duty switch and toggles', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(
      const TrackingOnline(
        connection: ConnectionStatus.connected,
        onDuty: false,
      ),
    );
    await _pump(tester, vm);
    expect(find.byType(SwitchListTile), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    verify(() => vm.toggleDuty()).called(1);
  });

  testWidgets('permission blocked shows settings button', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(
      const TrackingOnline(
        connection: ConnectionStatus.connected,
        onDuty: false,
        permissionBlocked: true,
      ),
    );
    await _pump(tester, vm);
    expect(find.text('Open settings to grant location'), findsOneWidget);
    await tester.tap(find.text('Open settings to grant location'));
    verify(() => vm.openSettings()).called(1);
  });

  testWidgets('logout action calls logout', (WidgetTester tester) async {
    when(() => vm.state).thenReturn(const TrackingConnecting());
    await _pump(tester, vm);
    await tester.tap(find.byIcon(Icons.logout));
    verify(() => vm.logout()).called(1);
  });
}
