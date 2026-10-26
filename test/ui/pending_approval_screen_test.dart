import 'package:fleet_pulse_mobile/state/approval_check_state.dart';
import 'package:fleet_pulse_mobile/ui/screens/pending_approval_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements PendingApprovalViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

void main() {
  Future<void> pump(WidgetTester tester, _MockVm vm) {
    return tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: InkRipple.splashFactory),
        home: ChangeNotifierProvider<PendingApprovalViewModel>.value(
          value: vm,
          child: const PendingApprovalScreen(),
        ),
      ),
    );
  }

  testWidgets('renders message and returns to login', (
    WidgetTester tester,
  ) async {
    final _MockVm vm = new _MockVm();
    when(vm.backToLogin).thenAnswer((_) async {});
    when(() => vm.state).thenReturn(const ApprovalWaiting());
    await pump(tester, vm);

    expect(
      find.text('Your account is awaiting admin approval'),
      findsOneWidget,
    );
    await tester.tap(find.text('Back to Login'));
    verify(vm.backToLogin).called(1);
  });
  testWidgets('the courier can ask again whether the account is approved', (
    WidgetTester tester,
  ) async {
    final _MockVm vm = new _MockVm();
    when(vm.checkAgain).thenAnswer((_) async {});
    when(() => vm.state).thenReturn(const ApprovalStillPending());
    await pump(tester, vm);

    expect(find.text('Still waiting for approval.'), findsOneWidget);
    await tester.tap(find.text('Check again'));
    verify(vm.checkAgain).called(1);
  });

  testWidgets('a check that could not be made says why', (
    WidgetTester tester,
  ) async {
    final _MockVm vm = new _MockVm();
    when(
      () => vm.state,
    ).thenReturn(const ApprovalCheckFailed('The fleet could not be reached.'));
    await pump(tester, vm);

    expect(find.text('The fleet could not be reached.'), findsOneWidget);
  });
}
