import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/credential_ui_state.dart';
import 'package:kinetix_courier/ui/widgets/seal/holder_runtime_view.dart';
import 'package:kinetix_courier/viewmodels/credential_view_model.dart';
import 'package:provider/provider.dart';

class CredentialScreen extends StatefulWidget {
  const CredentialScreen({super.key});

  @override
  State<CredentialScreen> createState() => _CredentialScreenState();
}

class _CredentialScreenState extends State<CredentialScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<CredentialViewModel>().load());
  }

  @override
  Widget build(BuildContext context) {
    final CredentialViewModel vm = context.watch<CredentialViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: vm.back),
        title: const Text('My credential'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            HolderRuntimeView(controller: vm.holder),
            Expanded(
              child: switch (vm.state) {
                CredentialLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                CredentialAbsent(
                  :final bool requesting,
                  :final Failure? error,
                ) =>
                  _Absent(
                    requesting: requesting,
                    error: error,
                    onRequest: vm.request,
                  ),
                CredentialShowing(
                  :final CourierCredential credential,
                  :final bool requesting,
                  :final Failure? error,
                ) =>
                  _Showing(
                    credential: credential,
                    requesting: requesting,
                    error: error,
                    onRequest: vm.request,
                    onShow: vm.showToVerifier,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Absent extends StatelessWidget {
  const _Absent({
    required this.requesting,
    required this.error,
    required this.onRequest,
  });

  final bool requesting;
  final Failure? error;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'A credential lets you show a lender or an employer how much you have '
          'delivered and how you are rated, without sharing your account.',
        ),
        const SizedBox(height: 16),
        if (error != null)
          Text(error!.message, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: requesting ? null : onRequest,
          child: Text(requesting ? 'Asking…' : 'Get my credential'),
        ),
      ],
    );
  }
}

class _Showing extends StatelessWidget {
  const _Showing({
    required this.credential,
    required this.requesting,
    required this.error,
    required this.onRequest,
    required this.onShow,
  });

  final CourierCredential credential;
  final bool requesting;
  final Failure? error;
  final VoidCallback onRequest;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final bool ready = credential.standing == CredentialStanding.issued;
    final String rating = (credential.ratingHundredths / 100).toStringAsFixed(
      2,
    );
    final String issued = DateTime.fromMillisecondsSinceEpoch(
      credential.issueDay * Duration.millisecondsPerDay,
      isUtc: true,
    ).toIso8601String().substring(0, 10);

    return ListView(
      children: <Widget>[
        ListTile(
          title: const Text('Deliveries'),
          trailing: Text('${credential.deliveries}'),
        ),
        ListTile(title: const Text('Rating'), trailing: Text(rating)),
        ListTile(
          title: const Text('Days active'),
          trailing: Text('${credential.daysActive}'),
        ),
        ListTile(title: const Text('As of'), trailing: Text(issued)),
        ListTile(
          title: const Text('Status'),
          trailing: Text(switch (credential.standing) {
            CredentialStanding.issued => 'Ready',
            CredentialStanding.pending => 'Being issued',
            CredentialStanding.superseded => 'Replaced by a newer one',
          }),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              error!.message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: ready ? onShow : null,
          child: const Text('Show to a verifier'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: requesting ? null : onRequest,
          child: Text(requesting ? 'Asking…' : 'Update with today’s numbers'),
        ),
      ],
    );
  }
}
