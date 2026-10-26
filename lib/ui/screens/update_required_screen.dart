import 'package:fleet_pulse_mobile/viewmodels/update_required_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UpdateRequiredViewModel vm = context.watch<UpdateRequiredViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Update Required')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.system_update, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Update the app',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kinetix no longer accepts this version of FleetPulse Driver. '
              'Install the latest version from Google Play or the App Store, '
              'then open it again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: vm.tryAgain,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
