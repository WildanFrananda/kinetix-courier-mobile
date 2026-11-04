import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/present_ui_state.dart';
import 'package:kinetix_courier/ui/screens/present_screen.dart';
import 'package:kinetix_courier/viewmodels/present_view_model.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'fake_web_view_platform.dart';

class _MockVm extends Mock implements PresentViewModel {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  bool get hasListeners => false;
}

final PresentationOffer offer = new PresentationOffer(
  contractAddress: 'aa' * 32,
  predicateId: 'bb' * 32,
  challenge: 'cc' * 32,
  answerUrl: Uri.parse('https://verify.example/seal/answer'),
  label: 'Experienced courier',
  deliveries: 100,
  ratingHundredths: 450,
  daysActive: 90,
  issuedSince: '2026-09-29',
);

Future<void> _pump(WidgetTester tester, PresentViewModel vm) {
  return tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<PresentViewModel>.value(
        value: vm,
        child: const PresentScreen(),
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
    when(() => vm.confirm()).thenAnswer((_) async {});
    when(() => vm.shareLink()).thenAnswer((_) async {});
  });

  testWidgets('says exactly what the verifier will learn, and nothing more', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(new PresentAsking(offer));
    await _pump(tester, vm);

    expect(find.text('Experienced courier'), findsOneWidget);
    expect(find.text('at least 100'), findsOneWidget);
    expect(find.text('at least 4.50'), findsOneWidget);
    expect(find.text('2026-09-29 or later'), findsOneWidget);

    await tester.tap(find.text('Show'));
    await tester.tap(find.text('Not now'));

    verify(() => vm.confirm()).called(1);
    verify(() => vm.decline()).called(1);
  });

  testWidgets('keeps the courier informed while the phone proves', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(new PresentProving(offer));
    await _pump(tester, vm);

    expect(find.textContaining('about a minute'), findsOneWidget);
  });

  testWidgets('shows the answer as a code and offers the link', (
    WidgetTester tester,
  ) async {
    when(() => vm.state).thenReturn(
      new PresentAnswering(
        offer,
        new PresentedAnswer(
          frames: <String>['KSP1:t:1/1:abc'],
          link: Uri.parse('https://verify.example/seal/answer#abc'),
        ),
        0,
      ),
    );
    await _pump(tester, vm);

    expect(find.byType(QrImageView), findsOneWidget);

    await tester.tap(find.text('Send the link instead'));
    await tester.tap(find.text('Done'));

    verify(() => vm.shareLink()).called(1);
    verify(() => vm.done()).called(1);
  });
}
