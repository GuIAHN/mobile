import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/core/utils/formatters.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_conversation_card.dart';

Widget _subject(ChatConversation conversation, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.light(),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale), disableAnimations: true),
        child: child!),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ChatConversationCard(
          conversation: conversation,
          onTap: () {},
        ),
      ),
    ),
  );
}

ChatConversation _conversation({
  required String status,
  required bool isInquiry,
  double? price,
  int quantity = 1,
  double? unitPrice,
  double? deliveryCost,
  double? totalCost,
  String lastMessage = '',
  bool? lastMessageIsFromMe,
}) {
  return ChatConversation(
    id: 'offer-1',
    conversationId: 'conversation-1',
    threadId: 'request-1',
    participantName: 'Tienda RC-A1B2C3',
    participantAvatarUrl: 'https://example.com/private-profile.jpg',
    lastMessage: lastMessage,
    lastMessageIsFromMe: lastMessageIsFromMe,
    unreadCount: 0,
    lastMessageAt: DateTime.utc(2026, 8, 24),
    offerStatus: status,
    hasQuote: true,
    isInquiry: isInquiry,
    price: price,
    quantity: quantity,
    unitPrice: unitPrice,
    deliveryCost: deliveryCost,
    totalCost: totalCost,
    storeLogoUrl: 'https://example.com/private-logo.jpg',
  );
}

void main() {
  for (final width in [320.0, 430.0]) {
    testWidgets('keeps a multi-unit quote usable at $width and 2x text',
        (tester) async {
      tester.view.physicalSize = Size(width, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_subject(
          _conversation(
              status: 'SENT',
              isInquiry: false,
              price: 60,
              quantity: 3,
              unitPrice: 20,
              deliveryCost: 2,
              totalCost: 62,
              lastMessage: 'Hola',
              lastMessageIsFromMe: false),
          textScale: 2));
      await tester.pumpAndSettle();
      expect(find.text(Formatters.currency(62)), findsOneWidget);
      expect(
          tester
              .getSize(find.widgetWithText(ElevatedButton, 'Ver cotización'))
              .height,
          greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  for (final total in [null, 62.0]) {
    testWidgets('shows only the quoted total with delivery (server: $total)',
        (tester) async {
      await tester.pumpWidget(_subject(_conversation(
          status: 'SENT',
          isInquiry: false,
          price: 60,
          quantity: 3,
          unitPrice: 20,
          deliveryCost: 2,
          totalCost: total)));
      expect(find.text(Formatters.currency(62)), findsOneWidget);
      expect(find.text(Formatters.currency(60)), findsNothing);
      expect(find.text(Formatters.currency(20)), findsNothing);
      expect(find.text(Formatters.currency(2)), findsNothing);
      expect(find.text('Subtotal'), findsNothing);
      expect(find.text('Delivery'), findsNothing);
      expect(find.text('Total con delivery'), findsNothing);
      expect(find.text('Ver cotización'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shows an inquiry as a chat, not as a received quote',
      (tester) async {
    await tester.pumpWidget(
      _subject(_conversation(status: 'INQUIRY', isInquiry: true)),
    );

    expect(find.text('Aún sin cotización'), findsOneWidget);
    expect(find.text('Ver chat'), findsOneWidget);
    expect(find.text('Ver cotización'), findsNothing);
    expect(find.byKey(const Key('generic-store-avatar')), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Conversación con Tienda RC-A1B2C3, aún sin cotización'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, semanticsEnabled: true);

  testWidgets('keeps the profile generic while a quoted store uses an alias',
      (tester) async {
    await tester.pumpWidget(
      _subject(
        _conversation(status: 'SENT', isInquiry: false, price: 1250),
      ),
    );

    expect(find.text('Ver cotización'), findsOneWidget);
    expect(find.byKey(const Key('generic-store-avatar')), findsOneWidget);
    expect(find.byKey(const Key('revealed-store-avatar')), findsNothing);
  });

  testWidgets('labels a read outgoing preview with Tú', (tester) async {
    await tester.pumpWidget(
      _subject(
        _conversation(
          status: 'SENT',
          isInquiry: false,
          price: 1250,
          lastMessage: 'Gracias, quedo atento',
          lastMessageIsFromMe: true,
        ),
      ),
    );

    expect(
      find.text('Tú: Gracias, quedo atento', findRichText: true),
      findsOneWidget,
    );
  });
}
