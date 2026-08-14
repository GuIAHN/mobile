import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/notifications/domain/entities/user_notification.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_card.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_detail_sheet.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_time_formatter.dart';
import 'package:guiautomotriz_mobile/features/notifications/presentation/widgets/notification_visual_style.dart';

UserNotification _notification({String? body}) => UserNotification(
      id: 'n-1',
      type: 'offer.new',
      title: 'Nueva oferta',
      body: body ?? 'Taller Central envió una nueva oferta.',
      data: const {'offerId': 'offer-1'},
      isRead: false,
      createdAt: DateTime.utc(2026, 8, 14, 14, 42),
    );

Widget _subject(
  Widget child, {
  Size size = const Size(430, 932),
  double textScale = 1,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(
      size: size,
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  test('formats old and complete dates without external locale setup', () {
    expect(
      NotificationTimeFormatter.relative(
        DateTime.utc(2026, 8, 1, 10, 42),
        now: DateTime.utc(2026, 8, 14, 12),
      ),
      '01/08/2026',
    );
    expect(
      NotificationTimeFormatter.full(DateTime.utc(2026, 8, 14, 10, 42)),
      '14/08/2026 · 10:42',
    );
  });

  test('maps every backend notification family to a readable visual style',
      () {
    const expectedLabels = {
      'offer.new': 'Oferta',
      'message.new': 'Mensaje',
      'search.matched': 'Solicitud',
      'user.approved': 'Cuenta',
      'settlement.approved': 'Pago',
      'custom.kind': 'Notificación',
    };

    for (final entry in expectedLabels.entries) {
      final style = NotificationVisualStyle.forType(entry.key);
      expect(style.label, entry.value);
      expect(style.icon, isA<IconData>());
      expect(style.foreground, isA<Color>());
      expect(style.background, isA<Color>());
    }
  });

  testWidgets('card exposes its action and keeps a touch-friendly height',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _subject(
        Center(
          child: SizedBox(
            width: 280,
            child: NotificationCard(
              notification: _notification(),
              isMarking: false,
              onTap: () => taps++,
            ),
          ),
        ),
        size: const Size(320, 700),
        textScale: 2,
      ),
    );

    final action = find.bySemanticsLabel(
      'Abrir y marcar como leída: Nueva oferta',
    );
    expect(action, findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('notification-card-n-1'))).height,
      greaterThanOrEqualTo(80),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(action);
    expect(taps, 1);
  }, semanticsEnabled: true);

  testWidgets('detail sheet renders the complete long message without clipping',
      (tester) async {
    final longBody = List.generate(
      70,
      (index) => 'Detalle importante ${index + 1}.',
    ).join(' ');
    final notification = _notification(body: longBody);

    await tester.pumpWidget(
      _subject(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showNotificationDetailSheet(
              context,
              notification: notification,
            ),
            child: const Text('Abrir detalle'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva oferta'), findsOneWidget);
    expect(find.text(longBody), findsOneWidget);
    expect(find.text('MENSAJE'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Cerrar detalle de notificación'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('long detail remains scrollable on a small phone at 200% text',
      (tester) async {
    final longBody = List.generate(
      100,
      (index) => 'Línea extensa ${index + 1}.',
    ).join(' ');

    await tester.pumpWidget(
      _subject(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showNotificationDetailSheet(
              context,
              notification: _notification(body: longBody),
            ),
            child: const Text('Abrir detalle'),
          ),
        ),
        size: const Size(320, 700),
        textScale: 2,
      ),
    );
    await tester.tap(find.text('Abrir detalle'));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text(longBody), findsOneWidget);
    expect(tester.takeException(), isNull);

    final closeAction = find.bySemanticsLabel(
      'Cerrar detalle de notificación',
    );
    await tester.scrollUntilVisible(
      closeAction,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.getSize(closeAction).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);
}
