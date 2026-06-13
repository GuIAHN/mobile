/// Define el entorno de ejecución de la aplicación.
enum AppEnvironment { development, staging, production }

/// Variables de entorno para la app.
/// Cambia [current] al compilar para diferentes entornos.
class Env {
  Env._();

  /// Entorno activo. Modifica esto al compilar con --dart-define.
  static const AppEnvironment current = AppEnvironment.development;

  /// URL base de la API REST (NestJS).
  static String get baseUrl {
    switch (current) {
      case AppEnvironment.development:
        return 'http://localhost:3000/api';
      case AppEnvironment.staging:
        return 'https://staging-api.guiautomotriz.com/api';
      case AppEnvironment.production:
        return 'https://api.guiautomotriz.com/api';
    }
  }

  static bool get isDev => current == AppEnvironment.development;
  static bool get isProd => current == AppEnvironment.production;
}
