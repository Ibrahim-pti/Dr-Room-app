import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

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

  /// Host used in development. Android emulators reach the host machine's
  /// loopback through 10.0.2.2; everything else uses 127.0.0.1. Override with
  /// --dart-define=DEV_HOST=192.168.1.5 to test against a real device.
  static String get _devHost {
    const override = String.fromEnvironment('DEV_HOST');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  static String get _origin {
    switch (environment) {
      case Environment.prod:
        return 'https://api.drroom.com';
      case Environment.staging:
        return 'https://staging-api.drroom.com';
      case Environment.dev:
        return 'http://$_devHost:8000';
    }
  }

  static String get baseUrl => '$_origin/api';
  static String get storageUrl => '$_origin/storage';

  /// How long a single request may take before it is abandoned. Without this
  /// a stalled connection leaves the UI spinning forever.
  static const Duration requestTimeout = Duration(seconds: 30);
}
