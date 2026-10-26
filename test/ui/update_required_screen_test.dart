import 'package:fleet_pulse_mobile/ui/screens/update_required_screen.dart';
import 'package:fleet_pulse_mobile/viewmodels/update_required_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements UpdateRequiredViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

void main() {
  testWidgets(
    'says the app must be updated, asks for no credentials, and can try again',
    (WidgetTester tester) async {
      final _MockVm vm = new _MockVm();
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<UpdateRequiredViewModel>.value(
            value: vm,
            child: const UpdateRequiredScreen(),
          ),
        ),
      );

      expect(find.text('Update the app'), findsOneWidget);
      expect(find.textContaining('Google Play'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('password'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Try again'));

      verify(vm.tryAgain).called(1);
    },
  );
}
