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
          url = 'http://192.168.0.239:3000/api';
          break;
        case AppEnvironment.staging:
          url = 'https://staging-api.guiautomotriz.com/api';
          break;
        case AppEnvironment.production:
          url = 'https://api.guiautomotriz.com/api';
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
