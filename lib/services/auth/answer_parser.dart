import 'package:fleet_pulse_mobile/core/app_logger.dart';

abstract final class AnswerParser {
  static T? parse<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) fromJson, {
    required String from,
  }) {
    if (raw is! Map<String, dynamic>) {
      AppLogger.error('$from answered a body this app cannot read');

      return null;
    }

    try {
      return fromJson(raw);
    } on Object catch (e) {
      AppLogger.error('$from answered a shape this app cannot read', error: e);

      return null;
    }
  }
}
