import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/login_outcome.dart';

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
