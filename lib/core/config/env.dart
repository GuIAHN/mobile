import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Defines the execution environment of the application.
enum AppEnvironment { development, staging, production }

/// Environment variables for the app.
/// Change [current] when building for different environments.
class Env {
  Env._();

  /// Active environment. Modify this when building with --dart-define (e.g., --dart-define=ENV=production).
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'development');

  static AppEnvironment get current {
    switch (_envString) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
      default:
        return AppEnvironment.development;
    }
  }

  /// Base URL of the REST API (NestJS).
  static String get baseUrl {
    String url = const String.fromEnvironment('API_BASE_URL');
    if (url.isEmpty) {
      switch (current) {
        case AppEnvironment.development:
          if (kIsWeb) {
            url = 'http://localhost:3000/api';
          } else if (Platform.isAndroid) {
            // Android emulator loops back to host via 10.0.2.2
            url = 'http://10.0.2.2:3000/api';
          } else {
            // iOS Simulator / macOS / Windows / Linux
            // Using Mac's local IP for physical iPhone testing
            url = 'http://192.168.0.239:3000/api';
          }
          break;
        case AppEnvironment.staging:
          url = 'https://staging-api.guiautomotriz.com/api';
          break;
        case AppEnvironment.production:
          url = 'https://guia-api-test.onrender.com';
          break;
      }
    }

    if (!url.endsWith('/')) {
      url = '$url/';
    }
    return url;
  }

  static bool get isDev => current == AppEnvironment.development;
  static bool get isProd => current == AppEnvironment.production;
}
