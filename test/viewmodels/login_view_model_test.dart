import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';
import 'package:fleet_pulse_mobile/viewmodels/login_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSession extends Mock implements SessionRepository {}

void main() {
  late _MockSession session;
  late AppRouterState router;
  late LoginViewModel sut;

  const DriverSession signedIn = DriverSession(
    driverId: DriverId(1),
    token: 't',
    refreshToken: 'refresh-token',
  );
  const TwoFactorChallenge challenge = TwoFactorChallenge(
    challengeToken: 'challenge-1',
    expiresIn: 300,
  );

  setUpAll(() => registerFallbackValue(challenge));

  setUp(() {
    session = new _MockSession();
    router = new AppRouterState();
    sut = new LoginViewModel(router, session);
  });

  void logsIn(Result<LoginOutcome> outcome) {
    when(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => outcome);
  }

  void verifiesTo(Result<DriverSession> result) {
    when(
      () => session.verifySecondFactor(
        challenge: any(named: 'challenge'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> submitCredentials() async {
    sut
      ..setEmail('driver@kinetix.test')
      ..setPassword('secret');
    await sut.submit();
  }

  test('empty fields set an error and skip login', () async {
    await sut.submit();
    expect(sut.error, isNotNull);
    verifyNever(
      () => session.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  test('successful login routes to Tracking', () async {
    logsIn(const Ok<LoginOutcome>(LoggedIn(signedIn)));

    await submitCredentials();

    expect(router.stack.last, isA<TrackingRoute>());
  });

  test('failed login surfaces the message', () async {
    logsIn(
      const Err<LoginOutcome>(
        AuthFailure('The email or password is not correct.'),
      ),
    );

    await submitCredentials();

    expect(sut.error, 'The email or password is not correct.');
    expect(router.stack.last, isA<SplashRoute>());
  });

  test('an incomplete registration routes to the register form', () async {
    logsIn(const Err<LoginOutcome>(RegistrationIncompleteFailure()));

    await submitCredentials();

    expect(router.stack.last, isA<RegisterRoute>());
    expect(sut.error, contains('vehicle'));
  });

  group('a sign-in identity delays', () {
    test(
      'says how long to wait, counts down, and holds the submit until then',
      () {
        fakeAsync((FakeAsync async) {
          logsIn(
            const Err<LoginOutcome>(SignInDelayedFailure(Duration(seconds: 8))),
          );
          unawaited(submitCredentials());
          async.flushMicrotasks();

          expect(sut.delayed, isTrue);
          expect(
            sut.error,
            'Too many sign-in attempts. Try again in 8 seconds.',
          );

          async.elapse(const Duration(seconds: 3));
          expect(
            sut.error,
            'Too many sign-in attempts. Try again in 5 seconds.',
          );

          unawaited(sut.submit());
          async.flushMicrotasks();
          verify(
            () => session.login(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).called(1);

          async.elapse(const Duration(seconds: 5));
          expect(sut.delayed, isFalse);
          expect(sut.error, isNull);
          expect(router.stack.single, isA<SplashRoute>());

          sut.dispose();
        });
      },
    );

    test('keeps the code step: identity counted no attempt', () {
      fakeAsync((FakeAsync async) {
        logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
        verifiesTo(
          const Err<DriverSession>(SignInDelayedFailure(Duration(seconds: 2))),
        );
        unawaited(submitCredentials());
        async.flushMicrotasks();

        sut.setCode('123456');
        unawaited(sut.submitCode());
        async.flushMicrotasks();

        expect(sut.awaitingCode, isTrue);
        expect(sut.delayed, isTrue);
        expect(sut.submitting, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(sut.delayed, isFalse);

        sut.dispose();
      });
    });

    test('stops counting once the screen is gone', () {
      fakeAsync((FakeAsync async) {
        logsIn(
          const Err<LoginOutcome>(SignInDelayedFailure(Duration(seconds: 60))),
        );
        unawaited(submitCredentials());
        async.flushMicrotasks();

        sut.dispose();

        expect(async.periodicTimerCount, 0);
      });
    });
  });

  test('an administrator is told plainly, and stays signed out', () async {
    logsIn(const Err<LoginOutcome>(AdminAccountFailure()));

    await submitCredentials();

    expect(sut.error, contains('administrator'));
    expect(sut.awaitingCode, isFalse);
    expect(router.stack.single, isA<SplashRoute>());
  });

  test('an app identity does not accept asks for an update', () async {
    logsIn(const Err<LoginOutcome>(AppUpdateRequiredFailure()));

    await submitCredentials();

    expect(router.stack.single, isA<UpdateRequiredRoute>());
  });

  test('pending approval routes to PendingApprovalRoute', () async {
    logsIn(const Err<LoginOutcome>(PendingApprovalFailure()));

    await submitCredentials();

    expect(router.stack.single, isA<PendingApprovalRoute>());
  });

  group('an account with a second factor', () {
    test('asks for the code instead of failing', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));

      await submitCredentials();

      expect(sut.awaitingCode, isTrue);
      expect(sut.error, isNull);
      expect(router.stack.last, isA<SplashRoute>());
    });

    test('a valid code signs in with the challenge', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      verifiesTo(const Ok<DriverSession>(signedIn));
      await submitCredentials();

      sut.setCode(' 123456 ');
      await sut.submitCode();

      verify(
        () => session.verifySecondFactor(challenge: challenge, code: '123456'),
      ).called(1);
      expect(router.stack.last, isA<TrackingRoute>());
    });

    test('a code that is not six digits is not sent', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      await submitCredentials();

      sut.setCode('12ab');
      await sut.submitCode();

      expect(sut.error, contains('six-digit'));
      verifyNever(
        () => session.verifySecondFactor(
          challenge: any(named: 'challenge'),
          code: any(named: 'code'),
        ),
      );
    });

    test('a wrong code keeps the code step and shows why', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      verifiesTo(
        const Err<DriverSession>(RefusedFailure('That code is not valid')),
      );
      await submitCredentials();

      sut.setCode('000000');
      await sut.submitCode();

      expect(sut.awaitingCode, isTrue);
      expect(sut.error, 'That code is not valid');
      expect(sut.submitting, isFalse);
    });

    test('an expired challenge goes back to the password', () async {
      final DateTime start = DateTime.utc(2026, 10, 21, 8);
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      await withClock(new Clock.fixed(start), submitCredentials);

      sut.setCode('123456');
      await withClock(
        new Clock.fixed(start.add(const Duration(seconds: 301))),
        sut.submitCode,
      );

      expect(sut.awaitingCode, isFalse);
      expect(sut.error, contains('expired'));
      verifyNever(
        () => session.verifySecondFactor(
          challenge: any(named: 'challenge'),
          code: any(named: 'code'),
        ),
      );
    });

    test(
      'an accepted code whose answer was unreadable goes back to the password',
      () async {
        logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
        verifiesTo(
          const Err<DriverSession>(UnreadableAnswerFailure('Sign in again.')),
        );
        await submitCredentials();

        sut.setCode('123456');
        await sut.submitCode();

        expect(sut.awaitingCode, isFalse);
        expect(sut.error, 'Sign in again.');
      },
    );

    test(
      'a challenge with no attempts left goes back to the password, and says why',
      () async {
        logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
        verifiesTo(
          const Err<DriverSession>(
            ChallengeSpentFailure('Too many wrong codes. Sign in again.'),
          ),
        );
        await submitCredentials();

        sut.setCode('000000');
        await sut.submitCode();

        expect(sut.awaitingCode, isFalse);
        expect(sut.error, 'Too many wrong codes. Sign in again.');
        expect(sut.submitting, isFalse);
      },
    );

    test('an app identity does not accept asks for an update', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      verifiesTo(const Err<DriverSession>(AppUpdateRequiredFailure()));
      await submitCredentials();

      sut.setCode('123456');
      await sut.submitCode();

      expect(router.stack.single, isA<UpdateRequiredRoute>());
    });

    test('signing in again leaves the code step', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      await submitCredentials();

      sut.cancelCode();

      expect(sut.awaitingCode, isFalse);
    });
  });
}
