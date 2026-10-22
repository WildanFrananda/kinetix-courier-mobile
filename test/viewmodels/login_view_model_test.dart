import 'package:clock/clock.dart';
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

  test('pending approval routes to PendingApprovalRoute', () async {
    logsIn(const Err<LoginOutcome>(PendingApprovalFailure()));

    await submitCredentials();

    expect(router.stack.last, isA<PendingApprovalRoute>());
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

    test('signing in again leaves the code step', () async {
      logsIn(const Ok<LoginOutcome>(SecondFactorRequired(challenge)));
      await submitCredentials();

      sut.cancelCode();

      expect(sut.awaitingCode, isFalse);
    });
  });
}
