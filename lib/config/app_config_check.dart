import 'package:fleet_pulse_mobile/config/app_check_mode.dart';

abstract final class AppConfigCheck {
  static final RegExp _projectNumber = new RegExp(r'^[0-9]+$');

  static List<String> problems({
    required String httpBase,
    required String wsBase,
    required Map<String, String> firebase,
    required String appCheckProvider,
    required bool releaseBuild,
  }) {
    return <String>[
      ?_problemWith('HTTP_BASE', httpBase, 'https'),
      ?_problemWith('WS_BASE', wsBase, 'wss'),
      for (final MapEntry<String, String> define in firebase.entries)
        ?_firebaseProblem(define.key, define.value),
      ?_providerProblem(appCheckProvider, releaseBuild: releaseBuild),
    ];
  }

  static String? _problemWith(String name, String value, String scheme) {
    if (value.isEmpty) {
      return '$name is not set. Build with '
          '--dart-define-from-file=dart_defines/<environment>.json.';
    }

    final Uri? uri = Uri.tryParse(value);

    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return '$name is not an absolute URL: $value';
    }

    if (uri.scheme != scheme) {
      return '$name must use $scheme://, the edge takes no cleartext: $value';
    }

    if (uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      return '$name names the edge only, with no path, trailing slash, query '
          'or credentials: $value';
    }

    return null;
  }

  static String? _firebaseProblem(String name, String value) {
    if (value.isEmpty) {
      return '$name is not set. Copy it from the Firebase console into '
          'dart_defines/<environment>.json.';
    }

    if (name == 'FIREBASE_MESSAGING_SENDER_ID' &&
        !_projectNumber.hasMatch(value)) {
      return '$name must be the Firebase project number, digits only: $value';
    }

    return null;
  }

  static String? _providerProblem(String value, {required bool releaseBuild}) {
    final AppCheckMode? mode = AppCheckMode.fromDefine(value);

    if (mode == null) {
      return 'APP_CHECK_PROVIDER must be attestation or debug: "$value".';
    }

    if (mode == AppCheckMode.debug && releaseBuild) {
      return 'APP_CHECK_PROVIDER is debug, which a release build never uses. '
          'Build the lab as a debug build (bin/build lab), and production with '
          'attestation.';
    }

    return null;
  }
}
