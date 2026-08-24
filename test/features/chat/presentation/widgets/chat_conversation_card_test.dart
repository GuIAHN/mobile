import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/theme/app_theme.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_conversation_card.dart';

Widget _subject(ChatConversation conversation) {
  return MaterialApp(
    theme: AppTheme.light(),
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
    storeLogoUrl: 'https://example.com/private-logo.jpg',
  );
}

void main() {
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
