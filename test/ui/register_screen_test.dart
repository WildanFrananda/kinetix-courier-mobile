import 'package:fleet_pulse_mobile/ui/screens/register_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/register_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements RegisterViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}



Future<void> _pump(WidgetTester tester, RegisterViewModel vm) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: InkRipple.splashFactory),
      home: ChangeNotifierProvider<RegisterViewModel>.value(
        value: vm,
        child: const RegisterScreen(),
      ),
    ),
  );
}


void main() {
  late _MockVm vm;

  setUp(() {
    vm = new _MockVm();
    when(() => vm.submit()).thenAnswer((_) async {});
    when(() => vm.submitting).thenReturn(false);
    when(() => vm.error).thenReturn(null);
    when(() => vm.successMessage).thenReturn(null);
  });

  testWidgets('renders every field and submits', (WidgetTester tester) async {
    await _pump(tester, vm);
    expect(find.byType(TextField), findsNWidgets(6));
    for (final String label in <String>[
      'Full Name',
      'Email',
      'Phone Number',
      'Password (min. 12 characters)',
      'Vehicle Plate (e.g. B 1234 XYZ)',
      'Vehicle Capacity (kg)',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing field: $label');
    }
    final Finder submit = find.widgetWithText(
      FilledButton,
      'Submit Registration',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    verify(() => vm.submit()).called(1);
  });

  testWidgets('typing an email reaches the view model', (WidgetTester tester) async {
    when(() => vm.setEmail(any())).thenReturn(null);
    await _pump(tester, vm);

    final Finder email = find.widgetWithText(TextField, 'Email');
    await tester.ensureVisible(email);
    await tester.enterText(email, 'driver@kinetix.test');

    verify(() => vm.setEmail('driver@kinetix.test')).called(1);
  });

  testWidgets('shows error message', (WidgetTester tester) async {
    when(() => vm.error).thenReturn('name taken');
    await _pump(tester, vm);
    expect(find.text('name taken'), findsOneWidget);
  });

  testWidgets('shows success message', (WidgetTester tester) async {
    when(() => vm.successMessage).thenReturn('pending approval');
    await _pump(tester, vm);
    expect(find.text('pending approval'), findsOneWidget);
  });

  testWidgets('back to login', (WidgetTester tester) async {
    await _pump(tester, vm);
    final Finder back = find.text('Back to Login');
    await tester.ensureVisible(back);
    await tester.tap(back);
    verify(() => vm.backToLogin()).called(1);
  });
}
