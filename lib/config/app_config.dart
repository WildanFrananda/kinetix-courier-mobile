abstract final class AppConfig {
  static const String httpBase = String.fromEnvironment('HTTP_BASE');

  static const String wsBase = String.fromEnvironment('WS_BASE');

  static const String appCheckProvider = String.fromEnvironment(
    'APP_CHECK_PROVIDER',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static const String firebaseApiKeyAndroid = String.fromEnvironment(
    'FIREBASE_API_KEY_ANDROID',
  );

  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );

  static const String firebaseApiKeyIos = String.fromEnvironment(
    'FIREBASE_API_KEY_IOS',
  );

  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
  );

  static const Map<String, String> firebaseDefines = <String, String>{
    'FIREBASE_PROJECT_ID': firebaseProjectId,
    'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
    'FIREBASE_API_KEY_ANDROID': firebaseApiKeyAndroid,
    'FIREBASE_APP_ID_ANDROID': firebaseAppIdAndroid,
    'FIREBASE_API_KEY_IOS': firebaseApiKeyIos,
    'FIREBASE_APP_ID_IOS': firebaseAppIdIos,
  };

  static const String clientName = 'courier-app';

  static const String clientHeader = 'X-Kinetix-Client';

  static const String clientProofHeader = 'X-Firebase-AppCheck';

  static const String authPath = '/api/v1/auth';

  static const String couriersPath = '/api/v1/couriers';

  static const String matchingPath = '/api/v1/matching';

  static const String driverSocketPath = '/ws/v1/matching/driver';

  static const String socketProtocolVersion = '2.0.0';
}
