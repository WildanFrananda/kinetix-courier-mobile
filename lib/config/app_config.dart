abstract final class AppConfig {
  static const String httpBase = String.fromEnvironment('HTTP_BASE');

  static const String wsBase = String.fromEnvironment('WS_BASE');

  static const String authPath = '/api/v1/auth';

  static const String couriersPath = '/api/v1/couriers';

  static const String matchingPath = '/api/v1/matching';

  static const String driverSocketPath = '/ws/v1/matching/driver';

  static const String socketProtocolVersion = '2.0.0';
}
