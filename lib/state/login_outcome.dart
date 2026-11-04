import 'package:kinetix_courier/models/driver_session.dart';
import 'package:kinetix_courier/models/two_factor_challenge.dart';

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
