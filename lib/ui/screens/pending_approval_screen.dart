import 'package:fleet_pulse_mobile/state/approval_check_state.dart';
import 'package:fleet_pulse_mobile/viewmodels/pending_approval_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PendingApprovalViewModel vm = context
        .watch<PendingApprovalViewModel>();
    final ApprovalCheckState state = vm.state;

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Approval')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.hourglass_top, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Your account is awaiting admin approval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'This courier account is not approved to drive, or its approval '
              'was withdrawn. You can go on duty once an administrator '
              'approves it.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            switch (state) {
              ApprovalWaiting() ||
              ApprovalChecking() => const SizedBox.shrink(),
              ApprovalStillPending() => const Text(
                'Still waiting for approval.',
                textAlign: TextAlign.center,
              ),
              ApprovalCheckFailed(:final String message) => Text(
                message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            },
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state is ApprovalChecking ? null : vm.checkAgain,
              child: state is ApprovalChecking
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Check again'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: state is ApprovalChecking ? null : vm.backToLogin,
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
