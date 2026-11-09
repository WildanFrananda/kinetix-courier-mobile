import 'package:flutter/material.dart';
import 'package:kinetix_courier/core/core.dart';
import 'package:kinetix_courier/models/models.dart';
import 'package:kinetix_courier/state/present_ui_state.dart';
import 'package:kinetix_courier/ui/widgets/seal/holder_runtime_view.dart';
import 'package:kinetix_courier/viewmodels/present_view_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PresentScreen extends StatelessWidget {
  const PresentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final PresentViewModel vm = context.watch<PresentViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: vm.done),
        title: const Text('Show to a verifier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            HolderRuntimeView(controller: vm.holder),
            Expanded(
              child: switch (vm.state) {
                PresentScanning(:final Failure? error) => _Scanning(
                  error: error,
                  onScanned: vm.scanned,
                ),
                PresentAsking(
                  :final PresentationOffer offer,
                  :final Failure? error,
                ) =>
                  _Asking(
                    offer: offer,
                    error: error,
                    onConfirm: vm.confirm,
                    onDecline: vm.decline,
                  ),
                PresentProving() => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Preparing your answer. This takes about a minute; keep the app open.',
                    ),
                  ],
                ),
                PresentAnswering(
                  :final PresentedAnswer answer,
                  :final int frame,
                ) =>
                  _Answering(
                    answer: answer,
                    frame: frame,
                    onShare: vm.shareLink,
                    onDone: vm.done,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.error, required this.onScanned});

  final Failure? error;
  final void Function(String text) onScanned;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text('Scan the code the verifier shows you.'),
        const SizedBox(height: 12),
        Expanded(
          child: MobileScanner(
            onDetect: (BarcodeCapture capture) {
              final String? text = capture.barcodes.firstOrNull?.rawValue;

              if (text != null) {
                onScanned(text);
              }
            },
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!.message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }
}

class _Asking extends StatelessWidget {
  const _Asking({
    required this.offer,
    required this.error,
    required this.onConfirm,
    required this.onDecline,
  });

  final PresentationOffer offer;
  final Failure? error;
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final String rating = (offer.ratingHundredths / 100).toStringAsFixed(2);

    return ListView(
      children: <Widget>[
        Text(offer.label, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text(
          'The verifier will learn only that all of this is true of you:',
        ),
        ListTile(
          title: const Text('Deliveries'),
          trailing: Text('at least ${offer.deliveries}'),
        ),
        ListTile(
          title: const Text('Rating'),
          trailing: Text('at least $rating'),
        ),
        ListTile(
          title: const Text('Days active'),
          trailing: Text('at least ${offer.daysActive}'),
        ),
        ListTile(
          title: const Text('Numbers as of'),
          trailing: Text('${offer.issuedSince} or later'),
        ),
        const Text(
          'They will not see your name, your exact numbers or your account.',
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
        FilledButton(onPressed: onConfirm, child: const Text('Show')),
        TextButton(onPressed: onDecline, child: const Text('Not now')),
      ],
    );
  }
}

class _Answering extends StatelessWidget {
  const _Answering({
    required this.answer,
    required this.frame,
    required this.onShare,
    required this.onDone,
  });

  final PresentedAnswer answer;
  final int frame;
  final VoidCallback onShare;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Let the verifier scan this, or send them the link. It is valid for an hour.',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: QrImageView(
              data: answer.frames[frame],
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.L,
            ),
          ),
        ),
        FilledButton(
          onPressed: onShare,
          child: const Text('Send the link instead'),
        ),
        TextButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}
