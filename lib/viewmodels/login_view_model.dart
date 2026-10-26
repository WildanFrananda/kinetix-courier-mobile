import 'package:clock/clock.dart';
import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/mixins/sign_in_delay_mixin.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/repositories/session_repository.dart';
import 'package:fleet_pulse_mobile/routes/app_route.dart';
import 'package:fleet_pulse_mobile/routes/app_router_state.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

@injectable
class LoginViewModel extends ChangeNotifier with SignInDelayMixin {
  LoginViewModel(this._router, this._session);

  static final RegExp _sixDigits = new RegExp(r'^\d{6}$');

  final AppRouterState _router;
  final SessionRepository _session;

  String _email = '';
  String _password = '';
  String _code = '';
  bool _submitting = false;
  String? _error;
  TwoFactorChallenge? _challenge;
  DateTime? _challengeExpiresAt;

  bool get submitting => _submitting;
  String? get error => delayMessage ?? _error;
  bool get awaitingCode => _challenge != null;

  void setEmail(String v) => _email = v.trim();
  void setPassword(String v) => _password = v;
  void setCode(String v) => _code = v.trim();

  Future<void> submit() async {
    if (_submitting || delayed) {
      return;
    }

    if (_email.isEmpty || _password.isEmpty) {
      _error = 'email and password required';
      notifyListeners();

      return;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final Result<LoginOutcome> res = await _session.login(
      email: _email,
      password: _password,
    );

    switch (res) {
      case Ok<LoginOutcome>(value: LoggedIn()):
        _router.replaceAll(const TrackingRoute());
      case Ok<LoginOutcome>(
        value: SecondFactorRequired(:final TwoFactorChallenge challenge),
      ):
        _askForCode(challenge);
      case Err<LoginOutcome>(:final Failure failure):
        _refused(failure);
    }
  }

  Future<void> submitCode() async {
    final TwoFactorChallenge? challenge = _challenge;
    final DateTime? expiresAt = _challengeExpiresAt;
    if (challenge == null || _submitting || delayed) {
      return;
    }

    if (expiresAt != null && !clock.now().isBefore(expiresAt)) {
      _challenge = null;
      _error = 'The sign-in request expired. Sign in again.';
      notifyListeners();

      return;
    }

    if (!_sixDigits.hasMatch(_code)) {
      _error = 'Enter the six-digit code from your authenticator app.';
      notifyListeners();

      return;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    final Result<DriverSession> res = await _session.verifySecondFactor(
      challenge: challenge,
      code: _code,
    );

    res.fold((_) => _router.replaceAll(const TrackingRoute()), _refused);
  }

  void cancelCode() {
    _challenge = null;
    _challengeExpiresAt = null;
    _code = '';
    _error = null;
    notifyListeners();
  }

  void navigateToRegister() => _router.push(const RegisterRoute());

  void _askForCode(TwoFactorChallenge challenge) {
    _submitting = false;
    _challenge = challenge;
    _challengeExpiresAt = clock.now().add(
      new Duration(seconds: challenge.expiresIn),
    );
    _code = '';
    notifyListeners();
  }

  void _refused(Failure f) {
    _submitting = false;

    if (f is SignInDelayedFailure) {
      _error = null;
      delayFor(f.wait);
      notifyListeners();

      return;
    }

    if (f is AppUpdateRequiredFailure) {
      _challenge = null;
      _challengeExpiresAt = null;
      notifyListeners();
      _router.replaceAll(const UpdateRequiredRoute());

      return;
    }

    if (f is PendingApprovalFailure) {
      _challenge = null;
      notifyListeners();
      _router.replaceAll(const PendingApprovalRoute());

      return;
    }

    if (f is RegistrationIncompleteFailure) {
      _challenge = null;
      _error =
          'Your account has no vehicle yet. Finish registering to continue.';
      notifyListeners();
      _router.push(const RegisterRoute());

      return;
    }

    if (f is UnreadableAnswerFailure || f is ChallengeSpentFailure) {
      _challenge = null;
      _challengeExpiresAt = null;
      _code = '';
    }

    _error = f.message;
    notifyListeners();
  }
}
