import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/models.dart';

abstract interface class SessionRepository {
  Future<DriverSession?> currentSession();

  Future<Result<DriverSession>> login({
    required String email,
    required String password,
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
