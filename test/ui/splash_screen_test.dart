import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/ui/screens/splash_screen.dart';
import 'package:kinetix_courier/viewmodels/splash_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockVm extends Mock implements SplashViewModel {}

void main() {
  testWidgets('shows a spinner', (WidgetTester tester) async {
    final _MockVm vm = _MockVm();
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SplashViewModel>.value(
          value: vm,
          child: const SplashScreen(),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
