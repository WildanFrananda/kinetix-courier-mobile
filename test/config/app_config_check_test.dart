import 'dart:convert';
import 'dart:io';

import 'package:fleet_pulse_mobile/config/app_config_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Map<String, String> firebase = <String, String>{
    'FIREBASE_PROJECT_ID': 'kinetix-test',
    'FIREBASE_MESSAGING_SENDER_ID': '123456789012',
    'FIREBASE_API_KEY_ANDROID': 'android-key',
    'FIREBASE_APP_ID_ANDROID': '1:123456789012:android:abc',
    'FIREBASE_API_KEY_IOS': 'ios-key',
    'FIREBASE_APP_ID_IOS': '1:123456789012:ios:def',
  };

  List<String> check(
    String httpBase,
    String wsBase, {
    Map<String, String> firebaseDefines = firebase,
    String provider = 'attestation',
    bool releaseBuild = true,
  }) => AppConfigCheck.problems(
    httpBase: httpBase,
    wsBase: wsBase,
    firebase: firebaseDefines,
    appCheckProvider: provider,
    releaseBuild: releaseBuild,
  );

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

  for (final String name in firebase.keys) {
    test('an app built without $name refuses to start', () {
      final List<String> problems = check(
        'https://edge.example',
        'wss://edge.example',
        firebaseDefines: <String, String>{...firebase, name: ''},
      );

      expect(problems.single, contains('$name is not set'));
    });
  }

  test('the messaging sender id must be the project number', () {
    final List<String> problems = check(
      'https://edge.example',
      'wss://edge.example',
      firebaseDefines: <String, String>{
        ...firebase,
        'FIREBASE_MESSAGING_SENDER_ID': 'kinetix-test',
      },
    );

    expect(problems.single, contains('project number'));
  });

  test('a release build never starts with the debug provider', () {
    final List<String> problems = check(
      'https://edge.example',
      'wss://edge.example',
      provider: 'debug',
    );

    expect(problems.single, contains('release build never uses'));
  });

  test('a debug build may use the debug provider', () {
    expect(
      check(
        'https://edge.example',
        'wss://edge.example',
        provider: 'debug',
        releaseBuild: false,
      ),
      isEmpty,
    );
  });

  for (final String provider in <String>['', 'play_integrity']) {
    test('APP_CHECK_PROVIDER "$provider" is refused', () {
      expect(
        check(
          'https://edge.example',
          'wss://edge.example',
          provider: provider,
        ).single,
        contains('attestation or debug'),
      );
    });
  }

  final Map<String, bool> releaseBuilds = <String, bool>{
    'production': true,
    'lab': false,
  };

  for (final MapEntry<String, bool> environment in releaseBuilds.entries) {
    test(
      'dart_defines/${environment.key}.json names everything, and only the Firebase values are left for the console',
      () {
        final Map<String, dynamic> defines =
            jsonDecode(
                  new File(
                    'dart_defines/${environment.key}.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        final Map<String, String> firebaseDefines = <String, String>{
          for (final String name in firebase.keys)
            name: defines[name] as String,
        };

        final List<String> problems = check(
          defines['HTTP_BASE'] as String,
          defines['WS_BASE'] as String,
          firebaseDefines: firebaseDefines,
          provider: defines['APP_CHECK_PROVIDER'] as String,
          releaseBuild: environment.value,
        );

        expect(defines.keys, containsAll(firebase.keys));
        expect(
          problems,
          hasLength(
            firebaseDefines.values.where((String v) => v.isEmpty).length,
          ),
        );
        expect(problems, everyElement(contains('Firebase console')));
      },
    );
  }
}
