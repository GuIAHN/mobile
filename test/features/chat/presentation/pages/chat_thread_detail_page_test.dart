import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/chat_thread_detail_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  ChatThread thread(String id, {String searchMatchId = 'match-1'}) =>
      ChatThread(
        id: id,
        title: 'Toyota Corolla',
        requestType: ServiceType.spareParts,
        unreadCount: 0,
        conversationCount: 0,
        lastActivityAt: DateTime.utc(2026, 8, 24),
        clientName: 'Carlos',
        subcategory: 'Pastillas de freno',
        searchMatchId: searchMatchId,
      );

  ChatConversation inquiry(String id) => ChatConversation(
        id: id,
        threadId: 'request-1',
        participantName: 'Carlos',
        lastMessage: '',
        unreadCount: 0,
        lastMessageAt: DateTime.utc(2026, 8, 24),
        searchMatchId: 'match-1',
        isInquiry: true,
      );

  Widget subject({
    required ChatRepository repository,
    required List<ChatThread> threads,
  }) {
    final router = GoRouter(
      initialLocation: '/sales/request-1',
      routes: [
        GoRoute(
          path: '/sales',
          builder: (_, __) => const Scaffold(body: Text('Ventas')),
        ),
        GoRoute(
          path: '/sales/:requestId',
          builder: (_, state) => ChatThreadDetailPage(
            threadId: state.pathParameters['requestId']!,
          ),
        ),
        GoRoute(
          path: '/chats/:conversationId',
          builder: (_, __) => const Scaffold(body: Text('Chat abierto')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        currentRoleProvider.overrideWithValue(UserRole.store),
        chatRepositoryProvider.overrideWithValue(repository),
        storeSalesRequestsProvider.overrideWith(
          (ref) async => ChatThreadsResult(
            threads: threads,
          ),
        ),
        chatConversationsProvider('request-1').overrideWith(
          (ref) async => const [],
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('never substitutes another request for a missing deep link',
      (tester) async {
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(repository: repository, threads: [thread('other-request')]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solicitud no disponible'), findsOneWidget);
    expect(find.text('Toyota Corolla'), findsNothing);
    expect(find.text('INICIAR CHAT CON EL CLIENTE'), findsNothing);
    verifyNever(
      () => repository.createQuote(
        threadId: any(named: 'threadId'),
        searchMatchId: any(named: 'searchMatchId'),
        price: any(named: 'price'),
        deliveryCost: any(named: 'deliveryCost'),
        brand: any(named: 'brand'),
        photoPath: any(named: 'photoPath'),
      ),
    );
  });

  testWidgets('submits the start-chat inquiry only once while pending',
      (tester) async {
    final repository = _MockChatRepository();
    final completer = Completer<Either<Failure, ChatConversation>>();
    when(
      () => repository.createQuote(
        threadId: any(named: 'threadId'),
        searchMatchId: any(named: 'searchMatchId'),
        price: any(named: 'price'),
        deliveryCost: any(named: 'deliveryCost'),
        brand: any(named: 'brand'),
        photoPath: any(named: 'photoPath'),
      ),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(
      subject(repository: repository, threads: [thread('request-1')]),
    );
    await tester.pumpAndSettle();

    final action = find.text('INICIAR CHAT CON EL CLIENTE');
    await tester.tap(action);
    await tester.tap(action);

    verify(
      () => repository.createQuote(
        threadId: 'request-1',
        searchMatchId: 'match-1',
        price: null,
        deliveryCost: null,
        brand: null,
        photoPath: null,
      ),
    ).called(1);

    completer.complete(Right(inquiry('conversation-1')));
    await tester.pumpAndSettle();
    expect(find.text('Chat abierto'), findsOneWidget);
  });
}
