import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/utils/formatters.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/confirm_purchase_dialog.dart';

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets('supports a $width phone with large text and safe areas',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  disableAnimations: true,
                  padding: const EdgeInsets.only(top: 44, bottom: 34)),
              child: child!),
          home: Scaffold(
              body: ConfirmPurchaseDialog(
                  details: ChatConversation(
                      id: 'c',
                      threadId: 'r',
                      participantName: 'Tienda de repuestos',
                      lastMessage: '',
                      unreadCount: 0,
                      lastMessageAt: DateTime.now(),
                      price: 50,
                      quantity: 2,
                      unitPrice: 25,
                      deliveryCost: 5,
                      totalCost: 55,
                      vehicleTitle: 'Chevrolet C-20 2026',
                      subcategoryName: 'Motor')))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final total in [null, 55.0]) {
    testWidgets('confirms only the total including delivery (server: $total)',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ConfirmPurchaseDialog(
                  details: ChatConversation(
                      id: 'conversation-1',
                      threadId: 'request-1',
                      participantName: 'Repuestos Central',
                      lastMessage: '',
                      unreadCount: 0,
                      lastMessageAt: DateTime.utc(2026, 9, 3),
                      price: 50,
                      quantity: 2,
                      unitPrice: 25,
                      deliveryCost: 5,
                      totalCost: total)))));
      expect(find.text(Formatters.currency(55)), findsOneWidget);
      expect(find.text(Formatters.currency(50)), findsNothing);
      expect(find.text(Formatters.currency(25)), findsNothing);
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('Delivery'), findsNothing);
      expect(find.text('Sí, Confirmar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeps spare brand together with catch-all requester context',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfirmPurchaseDialog(
            details: ChatConversation(
              id: 'conversation-1',
              threadId: 'request-1',
              participantName: 'Repuestos Central',
              lastMessage: '',
              unreadCount: 0,
              lastMessageAt: DateTime.utc(2026, 9, 3),
              price: 125,
              spareBrand: 'Denso Premium',
              subcategoryName: 'Nombre administrativo variable',
              subcategoryIsCatchAll: true,
              categoryName: 'Electricidad',
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Denso Premium · Electricidad › No sé cuál exactamente'),
      findsOneWidget,
    );
    expect(find.text('Nombre administrativo variable'), findsNothing);
  });
}
