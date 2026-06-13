/// Nombres de ruta centralizados.
/// Úsalos siempre en vez de strings literales al navegar.
abstract class RouteNames {
  RouteNames._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerUser = '/register/user';
  static const String registerWorkshop = '/register/workshop';
  static const String registerMechanic = '/register/mechanic';
  static const String registerStore = '/register/store';
  static const String registerVehicles = '/register/vehicles';
  static const String forgotPassword = '/forgot-password';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const String home = '/home';

  // ── Vehículos ─────────────────────────────────────────────────────────────
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static String vehicleDetailPath(String id) => '/vehicles/$id';
}
