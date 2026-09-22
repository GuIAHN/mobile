import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/features/auth/domain/entities/user.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/widgets/chat_conversation_card.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocketService extends Mock implements SocketService {}

void main() {
  testWidgets('does not hydrate previews whose authorship is already known',
      (tester) async {
    final socket = _MockSocketService();
    var hydrationCalls = 0;
    when(() => socket.onMessage).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socketServiceProvider.overrideWithValue(socket),
          currentUserProvider.overrideWithValue(
            const User(
              id: 'consumer-user',
              email: 'consumer@example.com',
              name: 'Carlos',
              role: UserRole.consumer,
            ),
          ),
          latestConversationMessageProvider(
            (
              conversationId: 'conversation-1',
              lastMessageAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
              lastMessage: 'Mensaje conocido',
            ),
          ).overrideWith(
            (ref) async {
              hydrationCalls++;
              return null;
            },
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RealtimeChatConversationCard(
              conversation: ChatConversation(
                id: 'offer-1',
                conversationId: 'conversation-1',
                threadId: 'request-1',
                participantName: 'Repuestos Central',
                lastMessage: 'Mensaje conocido',
                lastMessageIsFromMe: true,
                unreadCount: 0,
                lastMessageAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(hydrationCalls, 0);
    expect(
      find.text('Tú: Mensaje conocido', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('updates only when a message belongs to the card conversation',
      (tester) async {
    final socket = _MockSocketService();
    final messages =
        StreamController<Map<String, dynamic>>.broadcast(sync: true);
    when(() => socket.onMessage).thenAnswer((_) => messages.stream);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socketServiceProvider.overrideWithValue(socket),
          currentUserProvider.overrideWithValue(
            const User(
              id: 'consumer-user',
              email: 'consumer@example.com',
              name: 'Carlos',
              role: UserRole.consumer,
            ),
          ),
          latestConversationMessageProvider(
            (
              conversationId: 'conversation-1',
              lastMessageAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
              lastMessage: 'Mensaje anterior',
            ),
          ).overrideWith(
            (ref) async => ChatMessage(
              id: 'message-initial',
              conversationId: 'conversation-1',
              senderId: 'consumer-user',
              senderName: 'Carlos',
              isFromMe: true,
              content: 'Mensaje anterior',
              createdAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
              isRead: true,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RealtimeChatConversationCard(
              conversation: ChatConversation(
                id: 'offer-1',
                conversationId: 'conversation-1',
                threadId: 'request-1',
                participantName: 'Repuestos Central',
                lastMessage: 'Mensaje anterior',
                unreadCount: 0,
                lastMessageAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
                hasQuote: true,
                price: 125,
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tú: Mensaje anterior', findRichText: true),
      findsOneWidget,
    );

    messages.add(const {
      'id': 'message-other',
      'conversationId': 'conversation-2',
      'senderId': 'store-user',
      'content': 'No pertenece a este card',
      'read': false,
      'createdAt': '2026-08-20T12:01:00.000Z',
    });
    await tester.pump();

    expect(
      find.text('Tú: Mensaje anterior', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('No pertenece a este card'), findsNothing);

    messages.add(const {
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'store-user',
      'content': 'La pieza ya está disponible',
      'read': false,
      'createdAt': '2026-08-20T12:02:00.000Z',
    });
    await tester.pump();

    expect(
      find.text('Tú: Mensaje anterior', findRichText: true),
      findsNothing,
    );
    expect(
      find.text(
        'Repuestos Central: La pieza ya está disponible',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('mensajes sin leer')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await messages.close();
  }, semanticsEnabled: true);
}
