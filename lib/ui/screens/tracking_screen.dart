import 'package:fleet_pulse_mobile/core/core.dart';
import 'package:fleet_pulse_mobile/models/driver_availability.dart';
import 'package:fleet_pulse_mobile/models/enums.dart';
import 'package:fleet_pulse_mobile/models/telemetry_ping.dart';
import 'package:fleet_pulse_mobile/state/state.dart';
import 'package:fleet_pulse_mobile/viewmodels/tracking_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part '../widgets/tracking/online_view.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TrackingViewModel vm = context.watch<TrackingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking'),
        actions: <Widget>[
          IconButton(onPressed: vm.logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (vm.state) {
          TrackingConnecting() => const Center(
            child: CircularProgressIndicator(),
          ),
          TrackingOffline() => const Center(
            child: Text('Offline — reconnecting…'),
          ),
          TrackingOnline(
            :final ConnectionStatus connection,
            :final bool onDuty,
            :final DriverAvailability availability,
            :final bool permissionBlocked,
            :final TelemetryPing? lastPing,
            :final String? lastMessage,
          ) =>
            _OnlineView(
              vm: vm,
              connection: connection,
              onDuty: onDuty,
              availability: availability,
              permissionBlocked: permissionBlocked,
              lastPing: lastPing,
              message: lastMessage,
            ),
          TrackingFailed(:final Failure failure) => Center(
            child: Text('Failed: ${failure.message}'),
          ),
        },
      ),
    );
  }
}
