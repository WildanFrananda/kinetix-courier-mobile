abstract final class AppConfigCheck {
  static List<String> problems({
    required String httpBase,
    required String wsBase,
  }) {
    return <String>[
      ?_problemWith('HTTP_BASE', httpBase, 'https'),
      ?_problemWith('WS_BASE', wsBase, 'wss'),
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
}
