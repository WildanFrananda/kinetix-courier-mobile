import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';
import 'package:fleet_pulse_mobile/state/login_outcome.dart';

abstract interface class SessionRepository {
  Future<DriverSession?> currentSession();

  Future<Result<DriverProfile>> standing();

  Future<Result<LoginOutcome>> login({
    required String email,
    required String password,
  });

  Future<Result<DriverSession>> verifySecondFactor({
    required TwoFactorChallenge challenge,
    required String code,
  });

  Future<Result<DriverSession>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String vehiclePlate,
    required int capacityKg,
  });

  Future<void> logout();
}
