import 'package:fleet_pulse_mobile/core/failure.dart';
import 'package:fleet_pulse_mobile/models/driver_availability.dart';
import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';

sealed class TrackingState {
  const TrackingState();
}

class TrackingOffline extends TrackingState {
  const TrackingOffline();
}

class TrackingConnecting extends TrackingState {
  const TrackingConnecting();
}

class TrackingOnline extends TrackingState {
  const TrackingOnline({
    required this.connection,
    required this.onDuty,
    this.availability = DriverAvailability.offline,
    this.permissionBlocked = false,
    this.lastPing,
    this.lastMessage,
  });

  final ConnectionStatus connection;
  final bool onDuty;
  final DriverAvailability availability;
  final bool permissionBlocked;
  final TelemetryPing? lastPing;
  final String? lastMessage;
}

class TrackingFailed extends TrackingState {
  const TrackingFailed(this.failure);

  final Failure failure;
}
