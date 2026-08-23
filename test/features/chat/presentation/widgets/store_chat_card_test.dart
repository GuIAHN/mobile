import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/store_chat_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  ChatConversation conversation({
    bool hasQuote = true,
    double? price = 1250,
    String lastMessage = 'La pieza está lista para retirar.',
  }) {
    return ChatConversation(
      id: 'conversation-1',
      threadId: 'request-1',
      participantName: 'Repuestos Central',
      lastMessage: lastMessage,
      unreadCount: 3,
      lastMessageAt: DateTime.utc(2026, 8, 14),
      offerStatus: 'BOUGHT',
      hasQuote: hasQuote,
      price: price,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required ChatConversation value,
    double width = 375,
    double textScale = 1,
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
          ),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: StoreChatCard(
                conversation: value,
                consumerPerspective: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('orders identity, latest message and commercial summary',
      (tester) async {
    await pumpCard(tester, value: conversation());

    final nameRect = tester.getRect(find.text('Repuestos Central'));
    final messageRect =
        tester.getRect(find.byKey(const Key('chat-card-latest-message')));
    final summaryRect =
        tester.getRect(find.byKey(const Key('chat-card-commercial-summary')));
    final badgeRect =
        tester.getRect(find.byKey(const Key('chat-card-status-badge')));
    final priceRect = tester.getRect(find.byKey(const Key('chat-card-price')));

    expect(nameRect.top, lessThan(messageRect.top));
    expect(messageRect.bottom, lessThan(summaryRect.top));
    expect(badgeRect.center.dy, closeTo(priceRect.center.dy, 8));
    expect(priceRect.left - badgeRect.right, lessThanOrEqualTo(30));
    expect(find.text('COMPRADA'), findsOneWidget);
    expect(find.text(conversation().formattedPrice), findsOneWidget);
  });

  testWidgets('stacks status and price at large text without overflow',
      (tester) async {
    await pumpCard(
      tester,
      value: conversation(),
      width: 320,
      textScale: 2,
    );

    final badgeRect =
        tester.getRect(find.byKey(const Key('chat-card-status-badge')));
    final priceRect = tester.getRect(find.byKey(const Key('chat-card-price')));

    expect(badgeRect.bottom, lessThanOrEqualTo(priceRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a useful message state when the conversation is empty',
      (tester) async {
    await pumpCard(
      tester,
      value: conversation(
        hasQuote: false,
        price: null,
        lastMessage: '',
      ),
    );

    expect(find.text('Sin mensajes todavía'), findsOneWidget);
    expect(find.byKey(const Key('chat-card-price')), findsNothing);
    expect(find.text('COMPRADA'), findsOneWidget);
  });
}
