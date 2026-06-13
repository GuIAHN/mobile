import 'env.dart';

/// Configuración centralizada de la aplicación.
/// Agrega aquí constantes globales (timeouts, paginación, etc.).
class AppConfig {
  AppConfig._();

  // ── Red ─────────────────────────────────────────────────────────────────
  static const int connectTimeoutMs = 30000;
  static const int receiveTimeoutMs = 30000;
  static const int sendTimeoutMs = 30000;

  // ── Paginación ──────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;

  // ── API ─────────────────────────────────────────────────────────────────
  static String get apiBaseUrl => Env.baseUrl;

  // ── Logging ─────────────────────────────────────────────────────────────
  /// Solo loguear en entornos no productivos.
  static bool get enableLogging => !Env.isProd;
}
