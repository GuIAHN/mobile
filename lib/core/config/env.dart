import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'
    show kIsWeb, kReleaseMode, visibleForTesting;

/// Defines the execution environment of the application.
enum AppEnvironment { development, staging, production }

/// Environment variables for the app.
/// Change [current] when building for different environments.
class Env {
  Env._();

  static const String _cartoRasterTileUrl =
      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
  static const String _cartoBasemapApiKey =
      String.fromEnvironment('CARTO_BASEMAP_API_KEY');

  /// Active environment. Modify this when building with --dart-define (e.g., --dart-define=ENV=production).
  static const String _envString = String.fromEnvironment('ENV');

  static AppEnvironment get current => resolveEnvironment(
        _envString,
        isRelease: kReleaseMode,
      );

  /// Release artifacts must never silently point at a developer machine.
  /// An explicit ENV value still wins, which keeps local/profile workflows
  /// available when they are intentionally requested.
  @visibleForTesting
  static AppEnvironment resolveEnvironment(
    String value, {
    required bool isRelease,
  }) {
    switch (value.trim().toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      default:
        return isRelease
            ? AppEnvironment.production
            : AppEnvironment.development;
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
            url = 'http://10.184.9.109:3000/api';
          }
          break;
        case AppEnvironment.staging:
          url = 'https://staging-api.guiautomotriz.com/api';
          break;
        case AppEnvironment.production:
          url = 'https://guia-api-test.onrender.com/api';
          break;
      }
    }

    if (!url.endsWith('/')) {
      url = '$url/';
    }
    return url;
  }

  static bool get isProd => current == AppEnvironment.production;

  /// CARTO raster tile URL shared by every map in the application.
  static String get cartoBasemapUrl =>
      resolveCartoBasemapUrl(_cartoBasemapApiKey);

  @visibleForTesting
  static String resolveCartoBasemapUrl(String apiKey) {
    final normalizedKey = apiKey.trim();
    if (normalizedKey.isEmpty) return _cartoRasterTileUrl;

    return '$_cartoRasterTileUrl?key=${Uri.encodeQueryComponent(normalizedKey)}';
  }
}
