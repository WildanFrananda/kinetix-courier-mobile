import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static const String _name = 'KinetixCourier';

  static void debug(String message) {
    if (kDebugMode) {
      developer.log(message, name: _name);
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: _name, error: error, stackTrace: stackTrace);
  }
}
