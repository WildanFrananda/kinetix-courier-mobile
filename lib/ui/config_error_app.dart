import 'package:flutter/material.dart';

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({required this.problems, super.key});

  final List<String> problems;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FleetPulse Driver',
      home: Scaffold(
        appBar: AppBar(title: const Text('This build cannot start')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'The app was built without the address of the Kinetix edge, '
              'so it has nowhere to connect.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            for (final String problem in problems)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(problem),
              ),
          ],
        ),
      ),
    );
  }
}
