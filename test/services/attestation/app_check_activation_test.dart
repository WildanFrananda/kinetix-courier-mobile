import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fleet_pulse_mobile/config/app_check_mode.dart';
import 'package:fleet_pulse_mobile/services/attestation/app_check_activation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a release build attests with Play Integrity and App Attest', () {
    final (
      AndroidAppCheckProvider android,
      AppleAppCheckProvider apple,
    ) = AppCheckActivation.providersFor(
      AppCheckMode.attestation,
      releaseBuild: true,
    );

    expect(android, isA<AndroidPlayIntegrityProvider>());
    expect(apple, isA<AppleAppAttestProvider>());
  });

  test(
    'a release build never selects the debug provider, whatever it is told',
    () {
      final (
        AndroidAppCheckProvider android,
        AppleAppCheckProvider apple,
      ) = AppCheckActivation.providersFor(
        AppCheckMode.debug,
        releaseBuild: true,
      );

      expect(android, isA<AndroidPlayIntegrityProvider>());
      expect(apple, isA<AppleAppAttestProvider>());
    },
  );

  test('a lab debug build uses the debug provider', () {
    final (
      AndroidAppCheckProvider android,
      AppleAppCheckProvider apple,
    ) = AppCheckActivation.providersFor(
      AppCheckMode.debug,
      releaseBuild: false,
    );

    expect(android, isA<AndroidDebugProvider>());
    expect(apple, isA<AppleDebugProvider>());
  });

  test('a debug build told to attest attests', () {
    final (
      AndroidAppCheckProvider android,
      AppleAppCheckProvider apple,
    ) = AppCheckActivation.providersFor(
      AppCheckMode.attestation,
      releaseBuild: false,
    );

    expect(android, isA<AndroidPlayIntegrityProvider>());
    expect(apple, isA<AppleAppAttestProvider>());
  });

  test('Android and iOS each get their own Firebase app', () {
    const Map<String, String> defines = <String, String>{
      'FIREBASE_PROJECT_ID': 'kinetix-test',
      'FIREBASE_MESSAGING_SENDER_ID': '123456789012',
      'FIREBASE_API_KEY_ANDROID': 'android-key',
      'FIREBASE_APP_ID_ANDROID': '1:123456789012:android:abc',
      'FIREBASE_API_KEY_IOS': 'ios-key',
      'FIREBASE_APP_ID_IOS': '1:123456789012:ios:def',
    };

    final FirebaseOptions android = AppCheckActivation.optionsFor(
      TargetPlatform.android,
      defines,
    );
    final FirebaseOptions ios = AppCheckActivation.optionsFor(
      TargetPlatform.iOS,
      defines,
    );

    expect(android.apiKey, 'android-key');
    expect(android.appId, '1:123456789012:android:abc');
    expect(ios.apiKey, 'ios-key');
    expect(ios.appId, '1:123456789012:ios:def');
    expect(
      <String>{android.projectId, ios.projectId},
      <String>{'kinetix-test'},
    );
    expect(android.messagingSenderId, '123456789012');
  });
}
