part of '../../screens/tracking_screen.dart';

class _OnlineView extends StatelessWidget {
  const _OnlineView({
    required this.vm,
    required this.connection,
    required this.onDuty,
    required this.availability,
    required this.permissionBlocked,
    required this.lastPing,
    required this.message,
  });

  final TrackingViewModel vm;
  final ConnectionStatus connection;
  final bool onDuty;
  final DriverAvailability availability;
  final bool permissionBlocked;
  final TelemetryPing? lastPing;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(Icons.circle, size: 12, color: Colors.green),
            const SizedBox(width: 6),
            Text(connection.name),
          ],
        ),
        const SizedBox(height: 16),
        Text('Availability: ${availability.name}'),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('On duty'),
          value: onDuty,
          onChanged: (_) => vm.toggleDuty(),
        ),
        const SizedBox(height: 8),
        Text(
          lastPing == null
              ? 'Last ping: —'
              : 'Last ping: ${lastPing!.latitude.toStringAsFixed(5)}, '
                    '${lastPing!.longitude.toStringAsFixed(5)}',
        ),
        if (permissionBlocked)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: vm.openSettings,
              child: const Text('Open settings to grant location'),
            ),
          ),
        const Spacer(),
        if (message != null) Text(message!),
      ],
    );
  }
}
