import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/notifications/push_notifications_service.dart';

void main() {
  test('normalizes the enriched FCM navigation contract', () {
    final tap = NotificationTap.fromData(const {
      'tipo': 'message.new',
      'notificationId': 'notification-1',
      'conversationId': 'conversation-1',
    });

    expect(tap.type, 'message.new');
    expect(tap.notificationId, 'notification-1');
    expect(tap.data['conversationId'], 'conversation-1');
  });

  test('decodes local notification payloads and legacy ids', () {
    final tap = NotificationTap.fromPayload(
      '{"type":"offer.new","id":"notification-2",'
      '"searchRequestId":"request-2"}',
    );

    expect(tap.type, 'offer.new');
    expect(tap.notificationId, 'notification-2');
    expect(tap.data['searchRequestId'], 'request-2');
  });
}
