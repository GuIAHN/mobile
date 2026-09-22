import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/notifications/foreground_notification_toast_provider.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_provider.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_type.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocketService extends Mock implements SocketService {}

void main() {
  test('formats a message notification as sender and preview', () async {
    final socket = _MockSocketService();
    final notifications = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(notifications.close);
    when(() => socket.onNotification).thenAnswer((_) => notifications.stream);

    final container = ProviderContainer(
      overrides: [socketServiceProvider.overrideWithValue(socket)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      foregroundNotificationToastProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    notifications.add(const {
      'tipo': 'message.new',
      'titulo': 'Nuevo mensaje',
      'cuerpo': 'Eduardo Russo: La pieza está disponible',
    });
    await pumpEventQueue();

    final toast = container.read(notificationProvider).single;
    expect(toast.type, NotificationType.message);
    expect(toast.title, 'Eduardo Russo');
    expect(toast.message, 'La pieza está disponible');
  });
}
