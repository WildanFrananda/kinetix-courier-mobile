enum AppCheckMode {
  attestation,
  debug;

  static AppCheckMode? fromDefine(String value) {
    for (final AppCheckMode mode in AppCheckMode.values) {
      if (mode.name == value) {
        return mode;
      }
    }

    return null;
  }
}
