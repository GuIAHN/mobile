import 'env.dart';

/// Centralized configuration for the application.
/// Add global constants here (timeouts, pagination, etc.).
class AppConfig {
  AppConfig._();

  // ── Red ─────────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const int sendTimeoutMs = 30000;

  // ── Paginación ──────────────────────────────────────────────────────────
  // ── API ─────────────────────────────────────────────────────────────────
  static String get apiBaseUrl => Env.baseUrl;

  // ── Logging ─────────────────────────────────────────────────────────────
  /// Only enable logging in non-production environments.
  static bool get enableLogging => !Env.isProd;
}
