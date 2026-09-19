abstract final class AppConfig {
  static const String httpBase = String.fromEnvironment(
    'HTTP_BASE',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String wsBase = String.fromEnvironment(
    'WS_BASE',
    defaultValue: 'ws://10.0.2.2:4000',
  );

  static const String authPath = '/api/v1/auth';

  static const String couriersPath = '/api/v1/couriers';

  static const String matchingPath = '/api/v1/matching';
}
