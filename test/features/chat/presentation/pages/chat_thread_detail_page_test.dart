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
  ChatThread thread(
    String id, {
    String searchMatchId = 'match-1',
    String? details,
    String? partType,
    int? vehicleYear,
  }) =>
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
        details: details,
        partType: partType,
        vehicleYear: vehicleYear,
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
    UserRole role = UserRole.store,
    List<ChatConversation> conversations = const [],
    TextScaler textScaler = TextScaler.noScaling,
    EdgeInsets safeAreaPadding = EdgeInsets.zero,
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
        currentRoleProvider.overrideWithValue(role),
        chatRepositoryProvider.overrideWithValue(repository),
        storeSalesRequestsProvider.overrideWith(
          (ref) async => ChatThreadsResult(
            threads: threads,
          ),
        ),
        consumerRequestsProvider.overrideWith(
          (ref) async => ChatThreadsResult(
            threads: threads,
          ),
        ),
        chatConversationsProvider('request-1').overrideWith(
          (ref) async => conversations,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: textScaler,
            disableAnimations: true,
            padding: safeAreaPadding,
            viewPadding: safeAreaPadding,
          ),
          child: child!,
        ),
      ),
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

  testWidgets('places request text over the photo hero and offers filter below',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockChatRepository();
    final offer = ChatConversation(
      id: 'offer-1',
      threadId: 'request-1',
      participantName: 'Repuestos Central',
      lastMessage: 'Disponible',
      unreadCount: 0,
      lastMessageAt: DateTime.utc(2026, 8, 25),
      hasQuote: true,
      price: 32,
      distanceKm: 5.8,
    );

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [
          thread(
            'request-1',
            details: 'Preferiblemente marca CBK.',
            partType: 'ORIGINAL',
            vehicleYear: 2026,
          ),
        ],
        role: UserRole.consumer,
        conversations: [offer],
        safeAreaPadding: const EdgeInsets.only(top: 59, bottom: 34),
      ),
    );
    await tester.pumpAndSettle();

    final hero = find.byKey(const Key('request-photo-hero'));
    final filter = find.byKey(const Key('conversation-sort-filter'));
    expect(hero, findsOneWidget);
    expect(tester.getTopLeft(hero).dy, 0);
    expect(
      tester.getTopLeft(find.byTooltip('Volver')).dy,
      greaterThanOrEqualTo(59),
    );
    expect(
      find.descendant(
        of: hero,
        matching: find.text('Preferiblemente marca CBK.'),
      ),
      findsOneWidget,
    );
    expect(filter, findsOneWidget);
    expect(tester.getTopLeft(filter).dy,
        greaterThan(tester.getBottomLeft(hero).dy));
    expect(find.text('Ofertas recibidas'), findsNothing);
    expect(find.text('Recientes'), findsOneWidget);
    expect(find.text('Precio'), findsOneWidget);
    expect(find.text('Distancia'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('conversation-sort-recent-selected')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('conversation-sort-priceAsc-idle')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('conversation-sort-priceAsc-selected')),
      findsOneWidget,
    );
  });

  testWidgets('supports a small phone and enlarged text without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockChatRepository();
    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [
          thread(
            'request-1',
            details:
                'Busco pastillas silenciosas y resistentes para uso diario en ciudad.',
            partType: 'PERFORMANCE',
            vehicleYear: 2026,
          ),
        ],
        role: UserRole.consumer,
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('request-photo-hero')), findsOneWidget);
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -560),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conversation-sort-filter')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the hero operable in phone landscape', (tester) async {
    tester.view.physicalSize = const Size(700, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MockChatRepository();
    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [
          thread(
            'request-1',
            details: 'Preferiblemente marca CBK.',
            partType: 'ORIGINAL',
            vehicleYear: 2026,
          ),
        ],
        role: UserRole.consumer,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(find.byKey(const Key('request-photo-hero')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
