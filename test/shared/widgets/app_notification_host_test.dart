import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_provider.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_type.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_notification_host.dart';

void main() {
  testWidgets('renders above the router without requiring a navigator Overlay',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          builder: (context, child) => AppNotificationHost(
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Inicio')),
        ),
      ),
    );

    container.read(notificationProvider.notifier).show(
          type: NotificationType.message,
          title: 'Eduardo Russo',
          message: 'La pieza está disponible para retirar.',
          duration: const Duration(minutes: 1),
        );
    await tester.pump();

    expect(find.text('Eduardo Russo'), findsOneWidget);
    expect(find.byKey(const Key('app-notification-close')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
