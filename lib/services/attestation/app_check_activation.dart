import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fleet_pulse_mobile/config/app_check_mode.dart';
import 'package:fleet_pulse_mobile/config/app_config.dart';
import 'package:fleet_pulse_mobile/core/app_logger.dart';
import 'package:flutter/foundation.dart';

abstract final class AppCheckActivation {
  static FirebaseOptions optionsFor(
    TargetPlatform platform,
    Map<String, String> defines,
  ) {
    final String app =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? 'IOS'
        : 'ANDROID';

    return new FirebaseOptions(
      apiKey: _required(defines, 'FIREBASE_API_KEY_$app'),
      appId: _required(defines, 'FIREBASE_APP_ID_$app'),
      messagingSenderId: _required(defines, 'FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _required(defines, 'FIREBASE_PROJECT_ID'),
    );
  }

  static String _required(Map<String, String> defines, String name) {
    final String? value = defines[name];

    if (value == null || value.isEmpty) {
      throw new StateError('$name is not set');
    }

    return value;
  }

  static (AndroidAppCheckProvider, AppleAppCheckProvider) providersFor(
    AppCheckMode mode, {
    required bool releaseBuild,
  }) {
    if (releaseBuild || mode == AppCheckMode.attestation) {
      return (
        const AndroidPlayIntegrityProvider(),
        const AppleAppAttestProvider(),
      );
    }

    return (const AndroidDebugProvider(), const AppleDebugProvider());
  }

  static Future<String?> start(AppCheckMode mode) async {
    final (AndroidAppCheckProvider android, AppleAppCheckProvider apple) =
        providersFor(mode, releaseBuild: kReleaseMode);

    try {
      await Firebase.initializeApp(
        options: optionsFor(defaultTargetPlatform, AppConfig.firebaseDefines),
      );
      await FirebaseAppCheck.instance.activate(
        providerAndroid: android,
        providerApple: apple,
      );
    } on Object catch (e, stackTrace) {
      AppLogger.error(
        'Firebase App Check could not start',
        error: e,
        stackTrace: stackTrace,
      );

      return 'Firebase App Check could not start, so this app cannot prove it '
          'is genuine. Check the FIREBASE_* values in '
          'dart_defines/<environment>.json.';
    }

    return null;
  }
}
