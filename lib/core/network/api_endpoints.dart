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
  static const String changePassword = 'auth/change-password';

  // ── Vehículos ─────────────────────────────────────────────────────────────
  // ── Búsqueda de Proveedores ───────────────────────────────────────────────
  static const String searchMechanics = 'search/mechanics';
  static const String searchWorkshops = 'search/workshops';

  // ── Perfiles Públicos ─────────────────────────────────────────────────────
  static String mechanicDetail(String id) => 'mechanics/$id';
  static const String mechanicProfile = 'mechanics/me';
  static const String mechanicSpecialties = 'mechanics/me/specialties';
  static const String stores = 'stores';
  static String storeDetail(String id) => 'stores/$id';
  static const String storeSearchRequests = 'stores/me/search-requests';
  static String storeSearchRequestDetail(String requestId) =>
      '$storeSearchRequests/$requestId';
  static String storeSearchRequestDecline(String searchMatchId) =>
      'stores/me/search-requests/$searchMatchId/decline';
  static const String storeOwnCoverage = 'stores/me/coverage';

  // ── Home / Dashboard ──────────────────────────────────────────────────────
  static const String homeTopProviders = 'home/top-providers';

  // ── Google Places (proxied by the backend) ───────────────────────────────
  static const String placesSearch = 'places/search';

  // ── Notificaciones ────────────────────────────────────────────────────────
  static const String notifications = 'me/notifications';
  static const String notificationsReadAll = 'me/notifications/read-all';
  static const String notificationsUnreadCount =
      'me/notifications/unread-count';
  static String notificationRead(String id) => 'me/notifications/$id/read';

  // ── Búsqueda de Repuestos ─────────────────────────────────────────────────
  static const String searchMe = 'search/me';
  static String searchDetail(String requestId) => 'search/$requestId';
  static String searchOffers(String id) => 'search/$id/offers';
  static const String consumerPurchases = 'me/purchases';
  static String offerCancel(String id) => 'offers/$id/cancel';
  static String offerCancelSale(String id) => 'offers/$id/cancel-sale';

  // ── Subida de imágenes ────────────────────────────────────────────────────
  static const String requestImageUpload = 'upload/requests';
  static const String offerImageUpload = 'upload/offers';
  static const String userAvatarUpload = 'users/me/avatar';

  // ── Chat / Mensajería ──────────────────────────────────────────────────────

  // ── Ads ───────────────────────────────────────────────────────────────────
  static const String adsFeed = 'ads/feed';
  static String trackAdImpression(String id) => 'ads/$id/impression';
  static String trackAdClick(String id) => 'ads/$id/click';

  // ── Reports / Dashboard ───────────────────────────────────────────────────
  static const String storeDashboard = 'reports/store/dashboard';
  static const String storeResponseStatus = 'reports/store/response-status';
  static String storeMetric(String metricId) =>
      'reports/store/metrics/$metricId';
  static const String providerDashboard = 'reports/provider/dashboard';
}
