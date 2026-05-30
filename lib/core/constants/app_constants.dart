class AppConstants {
  const AppConstants._();

  static const String appName = 'Vault System';
  static const String splashTagline = 'Secure Your Digital Secrets';

  /// Android emulators usually need `http://10.0.2.2:8000/api` instead.
  static const String apiBaseUrl = 'http://localhost:8000/api';
  static const bool splashBootstrapEnabled = false;
  static const String splashBootstrapEndpoint = '/splash/bootstrap';
  static const String loginEndpoint = '/login';

  static const Duration splashMinimumDuration = Duration(milliseconds: 2200);
  static const Duration apiConnectTimeout = Duration(seconds: 12);
  static const Duration apiReceiveTimeout = Duration(seconds: 20);
}
