import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_courier/services/seal/holder_answers.dart';
import 'package:kinetix_courier/services/seal/holder_runtime_exception.dart';

void main() {
  test('is ready once the page says so, and again after a restart', () async {
    final HolderAnswers answers = new HolderAnswers();
    bool ready = false;

    unawaited(answers.ready.then((_) => ready = true));
    answers.received('{"id":"ready","ok":"true"}');
    await Future<void>.delayed(Duration.zero);

    expect(ready, isTrue);

    answers.restart();
    ready = false;
    unawaited(answers.ready.then((_) => ready = true));
    await Future<void>.delayed(Duration.zero);

    expect(ready, isFalse);
  });

  test('hands each answer to the call that asked for it', () async {
    final HolderAnswers answers = new HolderAnswers();
    final Completer<Map<String, String>> first =
        new Completer<Map<String, String>>();
    final Completer<Map<String, String>> second =
        new Completer<Map<String, String>>();
    final String firstId = answers.expect(first);
    final String secondId = answers.expect(second);

    answers
      ..received('{"id":"$secondId","ok":"true","transaction":"0a"}')
      ..received(
        '{"id":"$firstId","ok":"false","error":"the snapshot must be an object"}',
      );

    expect((await second.future)['transaction'], '0a');
    await expectLater(
      first.future,
      throwsA(
        isA<HolderRuntimeException>().having(
          (HolderRuntimeException e) => e.message,
          'message',
          'the snapshot must be an object',
        ),
      ),
    );
  });

  test('ignores what is not an answer to a pending call', () {
    final HolderAnswers answers = new HolderAnswers();
    final Completer<Map<String, String>> waiting =
        new Completer<Map<String, String>>();
    final String id = answers.expect(waiting);

    answers
      ..received('[]')
      ..received('{"id":"call-999","ok":"true"}')
      ..forget(id)
      ..received('{"id":"$id","ok":"true"}');

    expect(waiting.isCompleted, isFalse);
  });
}
