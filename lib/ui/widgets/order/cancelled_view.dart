part of '../../screens/order_screen.dart';

class _CancelledView extends StatelessWidget {
  const _CancelledView({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    );
  }
}
