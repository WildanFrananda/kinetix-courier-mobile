import 'package:fleet_pulse_mobile/models/driver_session.dart';
import 'package:fleet_pulse_mobile/models/two_factor_challenge.dart';

sealed class LoginOutcome {
  const LoginOutcome();
}

class LoggedIn extends LoginOutcome {
  const LoggedIn(this.session);

  final DriverSession session;
}

class SecondFactorRequired extends LoginOutcome {
  const SecondFactorRequired(this.challenge);

  final TwoFactorChallenge challenge;
}
