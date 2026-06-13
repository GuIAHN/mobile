/// Endpoints de la API REST (NestJS).
/// Agrupa todas las rutas como constantes para evitar strings dispersos.
abstract class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Vehículos ─────────────────────────────────────────────────────────────
  static const String vehicles = '/vehicles';
  static String vehicleById(String id) => '/vehicles/$id';
  static String vehicleServices(String id) => '/vehicles/$id/services';

  // ── Home / Dashboard ──────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';
}
