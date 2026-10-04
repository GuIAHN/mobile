import '../../../core/router/route_names.dart';

/// Traduce el contrato semántico de una notificación a una ruta interna.
///
/// El backend histórico no enviaba `tipo` en FCM, por eso la resolución
/// también reconoce los identificadores presentes en `data`.
abstract class NotificationRouteResolver {
  NotificationRouteResolver._();

  static String resolve({
    required String type,
    required Map<String, dynamic> data,
  }) {
    final explicitRoute =
        _value(data, const ['route', 'deepLink', 'deep_link']);
    if (_isSafeInternalRoute(explicitRoute)) return explicitRoute!;

    final conversationId = _value(
      data,
      const ['conversationId', 'conversation_id'],
    );
    final requestId = _value(
      data,
      const [
        'searchRequestId',
        'search_request_id',
        'requestId',
        'request_id',
      ],
    );
    final searchId = _value(data, const ['searchId', 'search_id']);

    if ((type.startsWith('message.') || type == 'offer.inquiry') &&
        conversationId != null) {
      return RouteNames.chatConversationPath(conversationId);
    }

    // En las notificaciones de una operación ya comprada, la presencia del
    // participante contrario identifica de forma estable el lado receptor.
    if (_value(data, const ['consumerId', 'consumer_id']) != null &&
        requestId != null) {
      return RouteNames.saleDetailPath(requestId);
    }
    if (_value(data, const ['storeUserId', 'store_user_id']) != null &&
        requestId != null) {
      return RouteNames.purchaseDetailPath(requestId);
    }

    if (type == 'search.matched' || (searchId != null && requestId == null)) {
      return searchId == null
          ? RouteNames.sales
          : RouteNames.saleDetailPath(searchId);
    }

    if (requestId != null) {
      return RouteNames.purchaseDetailPath(requestId);
    }

    if (conversationId != null) {
      return RouteNames.chatConversationPath(conversationId);
    }

    if (type.startsWith('settlement.') || type.startsWith('user.')) {
      return RouteNames.home;
    }

    return RouteNames.notifications;
  }

  static String? _value(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      final value = raw?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  static bool _isSafeInternalRoute(String? route) {
    if (route == null || !route.startsWith('/') || route.startsWith('//')) {
      return false;
    }
    return !route.contains('://');
  }
}
