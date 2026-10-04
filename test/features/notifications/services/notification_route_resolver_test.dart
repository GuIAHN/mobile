import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/notifications/services/notification_route_resolver.dart';

void main() {
  group('NotificationRouteResolver', () {
    test('opens messages and inquiries in their conversation', () {
      expect(
        NotificationRouteResolver.resolve(
          type: 'message.new',
          data: const {'conversationId': 'conversation-1'},
        ),
        RouteNames.chatConversationPath('conversation-1'),
      );
      expect(
        NotificationRouteResolver.resolve(
          type: 'offer.inquiry',
          data: const {
            'conversationId': 'conversation-2',
            'searchRequestId': 'request-2',
          },
        ),
        RouteNames.chatConversationPath('conversation-2'),
      );
    });

    test('opens store requests and sold offers in sales', () {
      expect(
        NotificationRouteResolver.resolve(
          type: 'search.matched',
          data: const {'searchId': 'request-1'},
        ),
        RouteNames.saleDetailPath('request-1'),
      );
      expect(
        NotificationRouteResolver.resolve(
          type: 'offer.delivered',
          data: const {
            'searchRequestId': 'request-2',
            'consumerId': 'consumer-1',
            'conversationId': 'conversation-2',
          },
        ),
        RouteNames.saleDetailPath('request-2'),
      );
    });

    test('opens consumer offers and purchases in purchase detail', () {
      expect(
        NotificationRouteResolver.resolve(
          type: 'offer.new',
          data: const {'searchRequestId': 'request-1'},
        ),
        RouteNames.purchaseDetailPath('request-1'),
      );
      expect(
        NotificationRouteResolver.resolve(
          type: 'offer.bought',
          data: const {
            'searchRequestId': 'request-2',
            'storeUserId': 'store-user-1',
            'conversationId': 'conversation-2',
          },
        ),
        RouteNames.purchaseDetailPath('request-2'),
      );
    });

    test('supports legacy push payloads without tipo', () {
      expect(
        NotificationRouteResolver.resolve(
          type: '',
          data: const {'conversationId': 'conversation-1'},
        ),
        RouteNames.chatConversationPath('conversation-1'),
      );
      expect(
        NotificationRouteResolver.resolve(
          type: '',
          data: const {'searchId': 'request-1'},
        ),
        RouteNames.saleDetailPath('request-1'),
      );
    });

    test('accepts safe explicit routes and rejects external URLs', () {
      expect(
        NotificationRouteResolver.resolve(
          type: 'custom.kind',
          data: const {'route': '/chats/conversation-1'},
        ),
        '/chats/conversation-1',
      );
      expect(
        NotificationRouteResolver.resolve(
          type: 'custom.kind',
          data: const {'route': 'https://malicious.example'},
        ),
        RouteNames.notifications,
      );
    });
  });
}
