import 'dart:convert';
import 'dart:io';

import 'package:fleet_pulse_mobile/config/app_config_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> check(String httpBase, String wsBase) =>
      AppConfigCheck.problems(httpBase: httpBase, wsBase: wsBase);

  test('an app built without the edge address refuses to start', () {
    final List<String> problems = check('', '');

    expect(problems, hasLength(2));
    expect(problems[0], contains('HTTP_BASE is not set'));
    expect(problems[1], contains('WS_BASE is not set'));
  });

  test('the edge over TLS passes', () {
    expect(check('https://edge.example', 'wss://edge.example:8443'), isEmpty);
  });

  test('cleartext is refused for both bases', () {
    final List<String> problems = check(
      'http://10.0.2.2:8000',
      'ws://10.0.2.2:4000',
    );

    expect(problems, hasLength(2));
    expect(problems, everyElement(contains('no cleartext')));
  });

  for (final String base in <String>[
    'https://edge.example/',
    'https://edge.example/api',
    'https://edge.example?x=1',
    'https://user:secret@edge.example',
  ]) {
    test('$base is refused: a base names the edge only', () {
      expect(check(base, 'wss://edge.example'), hasLength(1));
    });
  }

  test('a value that is not a URL is refused', () {
    expect(
      check('edge.example', 'wss://edge.example').single,
      contains('absolute'),
    );
  });

  for (final String environment in <String>['production', 'lab']) {
    test('dart_defines/$environment.json passes the check', () {
      final Map<String, dynamic> defines =
          jsonDecode(
                new File('dart_defines/$environment.json').readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(
        check(defines['HTTP_BASE'] as String, defines['WS_BASE'] as String),
        isEmpty,
      );
    });
  }
}
