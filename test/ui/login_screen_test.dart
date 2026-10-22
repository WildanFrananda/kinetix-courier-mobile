import 'package:fleet_pulse_mobile/ui/screens/login_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements LoginViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

Future<void> _pump(WidgetTester tester, LoginViewModel vm) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: ChangeNotifierProvider<LoginViewModel>.value(
        value: vm,
        child: const LoginScreen(),
      ),
    ),
  );
}

void main() {
  late _MockVm vm;

  setUp(() {
    vm = new _MockVm();
    when(() => vm.submit()).thenAnswer((_) async {});
    when(() => vm.submitCode()).thenAnswer((_) async {});
    when(() => vm.awaitingCode).thenReturn(false);
  });

  testWidgets('renders fields and submits', (WidgetTester tester) async {
    when(() => vm.submitting).thenReturn(false);
    when(() => vm.error).thenReturn(null);
    await _pump(tester, vm);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.byType(FilledButton));
    verify(() => vm.submit()).called(1);
  });

  testWidgets('submitting shows spinner and disables button', (
    WidgetTester tester,
  ) async {
    when(() => vm.submitting).thenReturn(true);
    when(() => vm.error).thenReturn(null);
    await _pump(tester, vm);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    verifyNever(() => vm.submit());
  });

  testWidgets('shows error text', (WidgetTester tester) async {
    when(() => vm.submitting).thenReturn(false);
    when(() => vm.error).thenReturn('invalid_credentials');
    await _pump(tester, vm);
    expect(find.text('invalid_credentials'), findsOneWidget);
  });

  testWidgets('a second factor asks for the code and verifies it', (
    WidgetTester tester,
  ) async {
    when(() => vm.submitting).thenReturn(false);
    when(() => vm.error).thenReturn(null);
    when(() => vm.awaitingCode).thenReturn(true);
    await _pump(tester, vm);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Authentication code'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));

    verify(() => vm.submitCode()).called(1);
    verifyNever(() => vm.submit());
  });
}
