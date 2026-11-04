import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/repositories/credential_repository.dart';
import 'package:kinetix_courier/routes/app_route.dart';
import 'package:kinetix_courier/routes/app_router_state.dart';
import 'package:kinetix_courier/services/device/screen_wake.dart';
import 'package:kinetix_courier/services/device/share_sheet.dart';
import 'package:kinetix_courier/services/seal/holder_runtime.dart';
import 'package:kinetix_courier/state/credential_ui_state.dart';
import 'package:kinetix_courier/state/present_ui_state.dart';
import 'package:kinetix_courier/viewmodels/credential_view_model.dart';
import 'package:kinetix_courier/viewmodels/present_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockCredentials extends Mock implements CredentialRepository {}

class _MockRuntime extends Mock implements HolderRuntime {}

class _MockWake extends Mock implements ScreenWake {}

class _MockShare extends Mock implements ShareSheet {}

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

final PresentedAnswer answer = new PresentedAnswer(
  frames: <String>['KSP1:t:1/2:a', 'KSP1:t:2/2:b'],
  link: Uri.parse('https://verify.example/seal/answer#ab'),
);

const CourierCredential credential = CourierCredential(
  id: '0b0e7f6e-1b7a-4c5e-9c1e-1f2a3b4c5d6e',
  standing: CredentialStanding.issued,
  issueDay: 20760,
  deliveries: 120,
  ratingHundredths: 470,
  daysActive: 95,
  placement: null,
);

void main() {
  late _MockCredentials credentials;
  late _MockWake wake;
  late _MockShare share;
  late AppRouterState router;

  setUpAll(() {
    registerFallbackValue(offer);
  });

  setUp(() {
    credentials = new _MockCredentials();
    wake = new _MockWake();
    share = new _MockShare();
    router = new AppRouterState();
    when(() => wake.keepOn()).thenAnswer((_) async {});
    when(() => wake.release()).thenAnswer((_) async {});
    when(() => share.share(any())).thenAnswer((_) async {});
  });

  group('showing a credential to a verifier', () {
    PresentViewModel model() => new PresentViewModel(
      router,
      credentials,
      new _MockRuntime(),
      wake,
      share,
    );

    test('asks the courier before anything is proved', () async {
      when(
        () => credentials.offerFor('code'),
      ).thenAnswer((_) async => new Ok<PresentationOffer>(offer));

      final PresentViewModel vm = model();

      await vm.scanned('code');

      expect(vm.state, isA<PresentAsking>());
      verifyNever(() => credentials.present(any()));
    });

    test(
      'keeps scanning, and says why, when the code is not a request',
      () async {
        when(() => credentials.offerFor('nope')).thenAnswer(
          (_) async =>
              const Err<PresentationOffer>(CredentialFailure('not_a_request')),
        );

        final PresentViewModel vm = model();

        await vm.scanned('nope');

        expect(
          (vm.state as PresentScanning).error?.message,
          'That code is not a request to show a credential.',
        );
      },
    );

    test(
      'keeps the screen on while proving, then cycles the answer frames and offers the link',
      () async {
        when(
          () => credentials.offerFor('code'),
        ).thenAnswer((_) async => new Ok<PresentationOffer>(offer));
        when(
          () => credentials.present(offer),
        ).thenAnswer((_) async => new Ok<PresentedAnswer>(answer));

        final PresentViewModel vm = model();

        await vm.scanned('code');
        await vm.confirm();

        expect(vm.state, isA<PresentAnswering>());
        verifyInOrder(<void Function()>[
          () => wake.keepOn(),
          () => credentials.present(offer),
          () => wake.release(),
        ]);

        await Future<void>.delayed(PresentViewModel.frameInterval * 1.5);

        expect((vm.state as PresentAnswering).frame, 1);

        await vm.shareLink();

        verify(
          () => share.share('https://verify.example/seal/answer#ab'),
        ).called(1);
        vm.dispose();
      },
    );

    test(
      'returns to the question with the reason when proving fails',
      () async {
        when(
          () => credentials.offerFor('code'),
        ).thenAnswer((_) async => new Ok<PresentationOffer>(offer));
        when(() => credentials.present(offer)).thenAnswer(
          (_) async =>
              const Err<PresentedAnswer>(CredentialFailure('not_issued_yet')),
        );

        final PresentViewModel vm = model();

        await vm.scanned('code');
        await vm.confirm();

        expect((vm.state as PresentAsking).error, isA<CredentialFailure>());
        verify(() => wake.release()).called(1);
      },
    );

    test('goes back when done', () {
      router.push(const PresentRoute());
      model().done();

      expect(router.stack.last, isA<SplashRoute>());
    });
  });

  group('the credential screen', () {
    CredentialViewModel model() =>
        new CredentialViewModel(router, credentials, new _MockRuntime());

    setUp(() {
      when(
        () => credentials.refreshPublicState(force: any(named: 'force')),
      ).thenAnswer((_) async => const Ok<Unit>(Unit.unit));
      when(
        () => credentials.prepareHolder(),
      ).thenAnswer((_) async => const Ok<Unit>(Unit.unit));
    });

    test('shows the stored credential and readies the holder', () async {
      when(
        () => credentials.current(),
      ).thenAnswer((_) async => const Ok<CourierCredential?>(credential));

      final CredentialViewModel vm = model();

      await vm.load();

      expect((vm.state as CredentialShowing).credential.deliveries, 120);
      verify(() => credentials.prepareHolder()).called(1);
    });

    test(
      'asks for a credential with fresh public state, and keeps the reason it was refused',
      () async {
        when(
          () => credentials.current(),
        ).thenAnswer((_) async => const Ok<CourierCredential?>(null));
        when(() => credentials.request()).thenAnswer(
          (_) async =>
              const Err<CourierCredential>(CredentialFailure('NO_DELIVERIES')),
        );

        final CredentialViewModel vm = model();

        await vm.load();
        await vm.request();

        expect(
          (vm.state as CredentialAbsent).error?.message,
          'A credential needs at least one delivered job.',
        );
        verify(() => credentials.refreshPublicState(force: true)).called(1);
      },
    );

    test('sends a signed-out courier to sign in', () async {
      when(
        () => credentials.current(),
      ).thenAnswer((_) async => const Err<CourierCredential?>(AuthFailure()));

      await model().load();

      expect(router.stack.single, isA<LoginRoute>());
    });

    test('opens the verifier flow', () {
      model().showToVerifier();

      expect(router.stack.last, isA<PresentRoute>());
    });

    group('following a credential being issued', () {
      final CourierCredential pending = credential.copyWith(
        standing: CredentialStanding.pending,
      );

      test('asks again until it is ready, then asks nothing more', () {
        fakeAsync((FakeAsync async) {
          CourierCredential latest = pending;

          when(
            () => credentials.current(),
          ).thenAnswer((_) async => new Ok<CourierCredential?>(latest));

          final CredentialViewModel vm = model();

          unawaited(vm.load());
          async.flushMicrotasks();
          clearInteractions(credentials);

          async.elapse(CredentialViewModel.pendingCheck);

          verify(() => credentials.current()).called(1);
          expect(
            (vm.state as CredentialShowing).credential.standing,
            CredentialStanding.pending,
          );

          latest = credential;
          async.elapse(CredentialViewModel.pendingCheck);

          verify(() => credentials.current()).called(1);
          expect(
            (vm.state as CredentialShowing).credential.standing,
            CredentialStanding.issued,
          );

          async.elapse(CredentialViewModel.pendingCheck * 5);

          verifyNever(() => credentials.current());
          vm.dispose();
        });
      });

      test('never asks about a credential that is already ready', () {
        fakeAsync((FakeAsync async) {
          when(
            () => credentials.current(),
          ).thenAnswer((_) async => const Ok<CourierCredential?>(credential));

          final CredentialViewModel vm = model();

          unawaited(vm.load());
          async.flushMicrotasks();
          clearInteractions(credentials);
          async.elapse(CredentialViewModel.pendingCheck * 5);

          verifyNever(() => credentials.current());
          vm.dispose();
        });
      });

      test('follows one it has just asked for', () {
        fakeAsync((FakeAsync async) {
          when(
            () => credentials.request(),
          ).thenAnswer((_) async => new Ok<CourierCredential>(pending));
          when(
            () => credentials.current(),
          ).thenAnswer((_) async => new Ok<CourierCredential?>(pending));

          final CredentialViewModel vm = model();

          unawaited(vm.request());
          async
            ..flushMicrotasks()
            ..elapse(CredentialViewModel.pendingCheck);

          verify(() => credentials.current()).called(1);
          vm.dispose();
        });
      });

      test('keeps the reason a repeated request was refused', () {
        fakeAsync((FakeAsync async) {
          when(
            () => credentials.current(),
          ).thenAnswer((_) async => new Ok<CourierCredential?>(pending));
          when(() => credentials.request()).thenAnswer(
            (_) async =>
                const Err<CourierCredential>(CredentialFailure('ISSUED_TODAY')),
          );

          final CredentialViewModel vm = model();

          unawaited(vm.load());
          async.flushMicrotasks();
          unawaited(vm.request());
          async
            ..flushMicrotasks()
            ..elapse(CredentialViewModel.pendingCheck);

          expect(
            (vm.state as CredentialShowing).error,
            isA<CredentialFailure>(),
          );
          vm.dispose();
        });
      });

      test('stops when the screen goes away', () {
        fakeAsync((FakeAsync async) {
          when(
            () => credentials.current(),
          ).thenAnswer((_) async => new Ok<CourierCredential?>(pending));

          final CredentialViewModel vm = model();

          unawaited(vm.load());
          async.flushMicrotasks();
          clearInteractions(credentials);
          vm.dispose();
          async.elapse(CredentialViewModel.pendingCheck * 5);

          verifyNever(() => credentials.current());
        });
      });

      test('ignores an answer that arrives after the screen went away', () {
        fakeAsync((FakeAsync async) {
          final Completer<Result<CourierCredential?>> answer =
              new Completer<Result<CourierCredential?>>();
          int asked = 0;

          when(() => credentials.current()).thenAnswer((_) {
            asked += 1;

            return asked == 1
                ? Future<Result<CourierCredential?>>.value(
                    new Ok<CourierCredential?>(pending),
                  )
                : answer.future;
          });

          final CredentialViewModel vm = model();

          unawaited(vm.load());
          async
            ..flushMicrotasks()
            ..elapse(CredentialViewModel.pendingCheck);
          vm.dispose();
          answer.complete(const Ok<CourierCredential?>(credential));
          async.flushMicrotasks();

          expect(
            (vm.state as CredentialShowing).credential.standing,
            CredentialStanding.pending,
          );
        });
      });
    });
  });
}
