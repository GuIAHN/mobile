import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/active_offer_header_card.dart';

void main() {
  ChatConversation offer(String status) => ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: status,
        hasQuote: true,
        price: 125,
        storeRating: 4.5,
        storeReviewCount: 12,
      );

  Future<void> pumpCard(
    WidgetTester tester,
    ChatConversation details, {
    VoidCallback? onCancel,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ActiveOfferHeaderCard(
              details: details,
              isStore: false,
              onCancelPressed: onCancel,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('offers cancellation only while a consumer purchase is bought',
      (tester) async {
    var pressed = false;
    await pumpCard(
      tester,
      offer('BOUGHT'),
      onCancel: () => pressed = true,
    );

    expect(find.text('Cancelar compra'), findsOneWidget);
    expect(find.text('4.5 (12)'), findsOneWidget);
    await tester.tap(find.text('Cancelar compra'));
    expect(pressed, isTrue);
  });

  testWidgets('renders cancelled as terminal and removes purchase actions',
      (tester) async {
    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'CANCELLED',
        hasQuote: true,
        price: 125,
        cancelSource: 'SYSTEM',
        cancelReason: 'Sin confirmación de entrega',
      ),
    );

    expect(find.text('COMPRA CANCELADA'), findsOneWidget);
    expect(find.text('Compra cancelada automáticamente'), findsOneWidget);
    expect(find.text('Sin confirmación de entrega'), findsOneWidget);
    expect(find.text('Cancelar compra'), findsNothing);
    expect(find.textContaining('Comprar Ahora'), findsNothing);
  });

  testWidgets('uses the backend total when delivery is included',
      (tester) async {
    await pumpCard(
      tester,
      ChatConversation(
        id: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 22),
        offerId: 'offer-1',
        offerStatus: 'SENT',
        hasQuote: true,
        price: 125,
        deliveryCost: 25,
        totalCost: 150,
      ),
    );

    expect(find.text(r'$150.00'), findsWidgets);
    expect(find.text('Total con delivery'), findsOneWidget);
  });
}
