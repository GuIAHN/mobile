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
  static const String workshops = '/workshops';
  static const String mechanics = '/mechanics-list';

  // ── Notificaciones ───────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Proveedores: Mecánicos y Talleres ─────────────────────────────────────
  static const String mechanicDetail = '/mechanics/:id';
  static String mechanicDetailPath(String id) => '/mechanics/$id';
  static const String storeDetail = '/stores/:id';
  static String storeDetailPath(String id) => '/stores/$id';

  // ── Vehículos ─────────────────────────────────────────────────────────────
  static const String vehicles = '/vehicles';
  static const String vehicleDetail = '/vehicles/:id';
  static String vehicleDetailPath(String id) => '/vehicles/$id';

  // ── Chats ─────────────────────────────────────────────────────────────────
  static const String chatInbox = '/chats';
  static const String chatConversation = '/chats/:conversationId';
  static String chatConversationPath(String conversationId) =>
      '/chats/$conversationId';

  // ── Compras / Ventas ─────────────────────────────────────────────────────
  static const String purchases = '/purchases';
  static const String purchaseDetail = '/purchases/:requestId';
  static String purchaseDetailPath(String requestId) => '/purchases/$requestId';
  static const String sales = '/sales';
  static const String saleDetail = '/sales/:requestId';
  static String saleDetailPath(String requestId) => '/sales/$requestId';

  // ── Reseñas ───────────────────────────────────────────────────────────────
  static const String providerReviews = '/reviews/:targetId';
  static String providerReviewsPath(String targetId) => '/reviews/$targetId';
}
