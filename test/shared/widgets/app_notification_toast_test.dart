import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_model.dart';
import 'package:guiautomotriz_mobile/core/notifications/notification_type.dart';
import 'package:guiautomotriz_mobile/shared/widgets/app_notification_toast.dart';

void main() {
  Future<void> pumpToast(
    WidgetTester tester, {
    double width = 320,
    double textScale = 1,
    bool disableAnimations = true,
    bool dismissible = true,
    VoidCallback? onDismissed,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 700),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: AppNotificationToast(
                  notification: NotificationModel(
                    id: 'message-1',
                    type: NotificationType.message,
                    title: 'Eduardo Russo',
                    message: 'La pieza está disponible para retirar.',
                    duration: const Duration(minutes: 1),
                    isDismissible: dismissible,
                  ),
                  onDismissed: onDismissed ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('is compact, accessible and safe with large text',
      (tester) async {
    await pumpToast(tester, textScale: 2);

    expect(find.text('Eduardo Russo'), findsOneWidget);
    expect(find.text('La pieza está disponible para retirar.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Nuevo mensaje.*Eduardo Russo')),
        findsOneWidget);
    expect(find.bySemanticsLabel('Cerrar notificación'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('app-notification-close'))).width,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('dismisses immediately when reduced motion is enabled',
      (tester) async {
    var dismissals = 0;
    await pumpToast(tester, onDismissed: () => dismissals += 1);

    await tester.tap(find.byKey(const Key('app-notification-close')));
    await tester.pump();

    expect(dismissals, 1);
  });

  testWidgets('supports a non-dismissible data state', (tester) async {
    await pumpToast(tester, width: 430, dismissible: false);

    expect(find.byKey(const Key('app-notification-close')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
