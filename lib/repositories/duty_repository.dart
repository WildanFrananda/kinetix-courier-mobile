import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';

abstract interface class DutyRepository {
  bool get onDuty;

  Stream<DriverAvailability> get availability;

  Stream<TelemetryPing> get sent;

  Stream<Failure> get problems;

  Future<Result<DriverAvailability>> goOnDuty();

  Future<Result<DriverAvailability>> goOffDuty();

  Future<void> openAppSettings();

  Future<void> dispose();
}
