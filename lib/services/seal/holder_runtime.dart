import 'dart:async';
import 'dart:convert';

import 'package:fleet_pulse_mobile/services/seal/holder_answers.dart';
import 'package:fleet_pulse_mobile/services/seal/holder_runtime_exception.dart';
import 'package:injectable/injectable.dart';
import 'package:webview_flutter/webview_flutter.dart';

@lazySingleton
class HolderRuntime {
  HolderRuntime();

  static const Duration _startTimeout = Duration(seconds: 90);

  static const Duration _answerTimeout = Duration(minutes: 5);

  final WebViewController controller = new WebViewController();

  final HolderAnswers _answers = new HolderAnswers();

  late final Future<void> _configured = _configure();

  Uri? _loaded;

  Future<void> start(Uri entry) async {
    if (_loaded == entry) {
      return _answers.ready;
    }

    _answers.restart();
    _loaded = entry;
    await _configured;
    await controller.loadRequest(entry);

    try {
      await _answers.ready.timeout(_startTimeout);
    } on TimeoutException {
      _loaded = null;

      throw const HolderRuntimeException('the holder page did not start');
    }
  }

  Future<Map<String, String>> call(
    String method,
    List<String> arguments,
  ) async {
    final Completer<Map<String, String>> answer =
        new Completer<Map<String, String>>();
    final String id = _answers.expect(answer);
    final String argumentList = <String>[
      jsonEncode(id),
      ...arguments.map(jsonEncode),
    ].join(', ');

    await controller.runJavaScript('sealHolder.$method($argumentList)');

    try {
      return await answer.future.timeout(_answerTimeout);
    } on TimeoutException {
      _answers.forget(id);

      throw const HolderRuntimeException('the holder did not answer');
    }
  }

  Future<void> _configure() async {
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.addJavaScriptChannel(
      'SealHolderBridge',
      onMessageReceived: (JavaScriptMessage message) =>
          _answers.received(message.message),
    );
  }
}
