/// REST API Endpoints (NestJS).
/// Groups all routes as constants to avoid hardcoded strings across the app.
abstract class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = 'auth/login';
  static const String socialLogin = 'auth/social/login';
  static const String register = 'auth/register';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';
  static const String me = 'users/me';
  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';

  // ── Vehículos ─────────────────────────────────────────────────────────────
  static const String vehicles = 'vehicles';
  static String vehicleById(String id) => 'vehicles/$id';
  static String vehicleServices(String id) => 'vehicles/$id/services';

  // ── Búsqueda de Proveedores ───────────────────────────────────────────────
  static const String searchMechanics = 'search/mechanics';
  static const String searchWorkshops = 'search/workshops';

  // ── Perfiles Públicos ─────────────────────────────────────────────────────
  static String mechanicDetail(String id) => 'mechanics/$id';
  static String storeDetail(String id) => 'stores/$id';
  static const String storeSearchRequests = 'stores/me/search-requests';

  // ── Home / Dashboard ──────────────────────────────────────────────────────
  static const String dashboard = 'dashboard';

  // ── Búsqueda de Repuestos ─────────────────────────────────────────────────
  static const String search = 'search';
  static const String searchMe = 'search/me';
  static String searchById(String id) => 'search/$id';
  static String searchClose(String id) => 'search/$id/close';
  static String searchOffers(String id) => 'search/$id/offers';

  // ── Chat / Mensajería ──────────────────────────────────────────────────────

  static const String conversationsFromOffer = 'conversations/from-offer';
  static const String conversationsDirect = 'conversations/direct';
  static String conversationMessages(String id) => 'conversations/$id/messages';
  static String conversationRead(String id) => 'conversations/$id/read';
  // ── Ads ───────────────────────────────────────────────────────────────────
  static const String adsFeed = 'ads/feed';
  static String trackAdImpression(String id) => 'ads/$id/impression';
  static String trackAdClick(String id) => 'ads/$id/click';
}
