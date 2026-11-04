import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/credential_ui_state.dart';
import 'package:kinetix_courier/ui/screens/credential_screen.dart';
import 'package:kinetix_courier/viewmodels/credential_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'fake_web_view_platform.dart';

class _MockVm extends Mock implements CredentialViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

const CourierCredential issued = CourierCredential(
  id: '0b0e7f6e-1b7a-4c5e-9c1e-1f2a3b4c5d6e',
  standing: CredentialStanding.issued,
  issueDay: 20760,
  deliveries: 120,
  ratingHundredths: 470,
  daysActive: 95,
  placement: CredentialPlacement(
    generation: 1,
    contractAddress: 'aa',
    leafIndex: '7',
  ),
);

Future<void> _pump(WidgetTester tester, CredentialViewModel vm) {
  return tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<CredentialViewModel>.value(
        value: vm,
        child: const CredentialScreen(),
      ),
    ),
  );
}

void main() {
  late _MockVm vm;

  setUp(() {
    WebViewPlatform.instance = new FakeWebViewPlatform();
    vm = new _MockVm();
    when(() => vm.holder).thenReturn(new WebViewController());
    when(() => vm.load()).thenAnswer((_) async {});
    when(() => vm.request()).thenAnswer((_) async {});
  });

  testWidgets(
    'offers a credential to a courier who has none, and says why one was refused',
    (WidgetTester tester) async {
      when(() => vm.state).thenReturn(
        const CredentialAbsent(error: CredentialFailure('NO_DELIVERIES')),
      );
      await _pump(tester, vm);

      expect(
        find.text('A credential needs at least one delivered job.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Get my credential'));

      verify(() => vm.request()).called(1);
    },
  );

  testWidgets('shows an issued credential and lets the courier show it', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(const CredentialShowing(issued));
    await _pump(tester, vm);

    expect(find.text('120'), findsOneWidget);
    expect(find.text('4.70'), findsOneWidget);
    expect(find.text('2026-11-03'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);

    await tester.tap(find.text('Show to a verifier'));

    verify(() => vm.showToVerifier()).called(1);
  });

  testWidgets('cannot show a credential still being issued', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(
      CredentialShowing(
        issued.copyWith(standing: CredentialStanding.pending, placement: null),
      ),
    );
    await _pump(tester, vm);

    expect(find.text('Being issued'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Show to a verifier'),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('waits while loading', (WidgetTester tester) async {
    when(() => vm.state).thenReturn(const CredentialLoading());
    await _pump(tester, vm);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
