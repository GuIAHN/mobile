import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/services/socket_service.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/usecases/get_chat_threads_usecase.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockSocketService extends Mock implements SocketService {}

class _MockGetChatThreadsUseCase extends Mock
    implements GetChatThreadsUseCase {}

void main() {
  test('hides a delivered chat when its review was handled locally', () async {
    ChatConversation conversation({
      required String id,
      required String status,
      bool hasReviewed = false,
    }) =>
        ChatConversation(
          id: id,
          threadId: 'request-$id',
          participantName: 'Tienda',
          lastMessage: 'Pedido entregado',
          unreadCount: 0,
          lastMessageAt: DateTime.utc(2026, 8, 28),
          offerStatus: status,
          hasReviewed: hasReviewed,
        );

    final visible = await filterVisibleChatConversations(
      [
        conversation(id: 'handled', status: 'DELIVERED'),
        conversation(id: 'pending', status: 'DELIVERED'),
        conversation(id: 'active', status: 'BOUGHT'),
      ],
      hasHandledReview: (id) async => id == 'handled',
    );

    expect(visible.map((item) => item.id), ['pending', 'active']);
  });

  test('hydrates authorship only for the exact current preview', () {
    final timestamp = DateTime.parse('2026-08-20T12:00:00.000Z');
    final conversation = ChatConversation(
      id: 'conversation-1',
      threadId: 'DIRECT',
      participantName: 'Repuestos Central',
      lastMessage: 'Mensaje leído',
      unreadCount: 0,
      lastMessageAt: timestamp,
    );
    ChatMessage latest({String content = 'Mensaje leído'}) => ChatMessage(
          id: 'message-1',
          conversationId: 'conversation-1',
          senderId: 'consumer-user',
          senderName: 'Carlos',
          isFromMe: true,
          content: content,
          createdAt: timestamp,
          isRead: true,
        );

    final hydrated = applyLatestMessageAuthorship(conversation, latest());
    final stale = applyLatestMessageAuthorship(
      conversation,
      latest(content: 'Mensaje anterior'),
    );

    expect(hydrated.lastMessageIsFromMe, isTrue);
    expect(hydrated.unreadCount, 0);
    expect(stale.lastMessageIsFromMe, isNull);
  });

  test('store sales refresh automatically after the socket reconnects',
      () async {
    final socket = _MockSocketService();
    final getThreads = _MockGetChatThreadsUseCase();
    final reconnected = StreamController<void>.broadcast();
    final matched = StreamController<Map<String, dynamic>>.broadcast();
    final offers = StreamController<Map<String, dynamic>>.broadcast();
    final messages = StreamController<Map<String, dynamic>>.broadcast();
    final notifications = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(reconnected.close);
    addTearDown(matched.close);
    addTearDown(offers.close);
    addTearDown(messages.close);
    addTearDown(notifications.close);

    when(() => socket.onReconnect).thenAnswer((_) => reconnected.stream);
    when(() => socket.onSearchMatched).thenAnswer((_) => matched.stream);
    when(() => socket.onOfferUpdated).thenAnswer((_) => offers.stream);
    when(() => socket.onMessage).thenAnswer((_) => messages.stream);
    when(() => socket.onNotification).thenAnswer((_) => notifications.stream);
    when(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'TO_ANSWER',
      ),
    ).thenAnswer(
      (_) async => const Right(
        ChatThreadsResult(threads: []),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        getChatThreadsUseCaseProvider.overrideWithValue(getThreads),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      storeSalesRequestsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.read(storeSalesRequestsProvider.future);
    verify(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'TO_ANSWER',
      ),
    ).called(1);

    reconnected.add(null);
    await pumpEventQueue();
    await container.read(storeSalesRequestsProvider.future);

    verify(
      () => getThreads(
        role: UserRole.store,
        statusFilter: 'TO_ANSWER',
      ),
    ).called(1);
  });

  test(
      'consumer requests stay loaded while only the matching chat card updates',
      () async {
    final socket = _MockSocketService();
    final getThreads = _MockGetChatThreadsUseCase();
    final reconnected = StreamController<void>.broadcast();
    final matched = StreamController<Map<String, dynamic>>.broadcast();
    final offers = StreamController<Map<String, dynamic>>.broadcast();
    final messages = StreamController<Map<String, dynamic>>.broadcast();
    final notifications = StreamController<Map<String, dynamic>>.broadcast();
    addTearDown(reconnected.close);
    addTearDown(matched.close);
    addTearDown(offers.close);
    addTearDown(messages.close);
    addTearDown(notifications.close);

    when(() => socket.onReconnect).thenAnswer((_) => reconnected.stream);
    when(() => socket.onSearchMatched).thenAnswer((_) => matched.stream);
    when(() => socket.onOfferUpdated).thenAnswer((_) => offers.stream);
    when(() => socket.onMessage).thenAnswer((_) => messages.stream);
    when(() => socket.onNotification).thenAnswer((_) => notifications.stream);
    when(
      () => getThreads(
        role: UserRole.consumer,
        statusFilter: 'ALL',
      ),
    ).thenAnswer(
      (_) async => const Right(
        ChatThreadsResult(threads: []),
      ),
    );

    final container = ProviderContainer(
      overrides: [
        socketServiceProvider.overrideWithValue(socket),
        getChatThreadsUseCaseProvider.overrideWithValue(getThreads),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      consumerRequestsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    final previewSubscription = container.listen(
      conversationRealtimeUpdateProvider('conversation-1'),
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(previewSubscription.close);

    await container.read(consumerRequestsProvider.future);

    messages.add(const {
      'id': 'message-other',
      'conversationId': 'conversation-2',
      'senderId': 'store-user',
      'content': 'Mensaje de otro chat',
      'read': false,
      'createdAt': '2026-08-20T12:01:00.000Z',
    });
    await pumpEventQueue();

    expect(
      container.read(
        conversationRealtimeUpdateProvider('conversation-1'),
      ),
      isNull,
    );

    messages.add(const {
      'id': 'message-1',
      'conversationId': 'conversation-1',
      'senderId': 'store-user',
      'content': 'Primer mensaje',
      'read': false,
      'createdAt': '2026-08-20T12:02:00.000Z',
    });
    await pumpEventQueue();

    messages.add(const {
      'id': 'message-2',
      'conversationId': 'conversation-1',
      'senderId': 'store-user',
      'content': 'Último mensaje',
      'read': false,
      'createdAt': '2026-08-20T12:03:00.000Z',
    });
    await pumpEventQueue();

    final update = container.read(
      conversationRealtimeUpdateProvider('conversation-1'),
    );
    final resolved = applyRealtimeConversationUpdate(
      ChatConversation(
        id: 'offer-1',
        conversationId: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: 'Mensaje anterior',
        unreadCount: 1,
        lastMessageAt: DateTime.parse('2026-08-20T12:00:00.000Z'),
      ),
      update,
      currentUserId: 'consumer-user',
    );

    expect(resolved.lastMessage, 'Último mensaje');
    expect(resolved.lastMessageIsFromMe, isFalse);
    expect(resolved.unreadCount, 3);
    expect(
      resolved.lastMessageAt,
      DateTime.parse('2026-08-20T12:03:00.000Z'),
    );

    final refreshedReadConversation = applyRealtimeConversationUpdate(
      ChatConversation(
        id: 'offer-1',
        conversationId: 'conversation-1',
        threadId: 'request-1',
        participantName: 'Repuestos Central',
        lastMessage: 'Último mensaje',
        unreadCount: 0,
        lastMessageAt: DateTime.parse('2026-08-20T12:03:00.000Z'),
      ),
      update,
      currentUserId: 'consumer-user',
    );
    expect(refreshedReadConversation.lastMessageIsFromMe, isFalse);
    expect(refreshedReadConversation.unreadCount, 0);

    verify(
      () => getThreads(
        role: UserRole.consumer,
        statusFilter: 'ALL',
      ),
    ).called(1);
  });
}
