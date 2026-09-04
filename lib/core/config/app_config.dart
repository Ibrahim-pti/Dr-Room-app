import 'package:flutter/foundation.dart' show kReleaseMode;

/// Build-time environment selection.
///
/// Pass one at build time, e.g.
///   flutter run --dart-define=ENV=dev
///   flutter build appbundle --dart-define=ENV=prod
///
/// Release builds default to prod so a forgotten flag can never ship an app
/// pointing at a development server.
enum Environment { dev, staging, prod }

class AppConfig {
  AppConfig._();

  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  static Environment get environment {
    switch (_envName) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static bool get isProd => environment == Environment.prod;

  static const String liveServerUrl = 'https://sys.shaqamonline.org';

  static String get _origin {
    const override = String.fromEnvironment('SERVER_URL');
    if (override.isNotEmpty) return override;

    switch (environment) {
      case Environment.prod:
      case Environment.staging:
      case Environment.dev:
        return liveServerUrl;
    }
  }

  static String get baseUrl => '$_origin/api';
  static String get storageUrl => '$_origin/storage';

  /// How long a single request may take before it is abandoned. Without this
  /// a stalled connection leaves the UI spinning forever.
  static const Duration requestTimeout = Duration(seconds: 30);
}