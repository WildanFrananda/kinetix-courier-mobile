import 'dart:async';
import 'dart:convert';

import 'package:kinetix_courier/services/seal/holder_runtime_exception.dart';

class HolderAnswers {
  final Map<String, Completer<Map<String, String>>> _pending =
      <String, Completer<Map<String, String>>>{};

  Completer<void> _ready = new Completer<void>();

  int _next = 0;

  Future<void> get ready => _ready.future;

  void restart() {
    if (_ready.isCompleted) {
      _ready = new Completer<void>();
    }
  }

  String expect(Completer<Map<String, String>> answer) {
    final String id = 'call-${_next++}';

    _pending[id] = answer;

    return id;
  }

  void forget(String id) {
    _pending.remove(id);
  }

  void received(String message) {
    final Object? decoded = jsonDecode(message);

    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final Map<String, String> answer = decoded.map(
      (String key, dynamic value) =>
          new MapEntry<String, String>(key, '$value'),
    );
    final String? id = answer['id'];

    if (id == 'ready') {
      if (!_ready.isCompleted) {
        _ready.complete();
      }

      return;
    }

    final Completer<Map<String, String>>? pending = _pending.remove(id);

    if (pending == null) {
      return;
    }

    if (answer['ok'] == 'true') {
      pending.complete(answer);
    } else {
      pending.completeError(
        new HolderRuntimeException(answer['error'] ?? 'the holder failed'),
      );
    }
  }
}
