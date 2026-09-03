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
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  ChatThread thread(
    String id, {
    String searchMatchId = 'match-1',
    String? details,
    String? partType,
    int? vehicleYear,
    bool hasOffer = false,
    bool isInquiry = false,
    String? matchState,
    String? offerStatus,
    double? offerPrice,
    String? conversationId,
    String? fotoUrl,
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
        hasOffer: hasOffer,
        isInquiry: isInquiry,
        matchState: matchState,
        offerStatus: offerStatus,
        offerPrice: offerPrice,
        conversationId: conversationId,
        fotoUrl: fotoUrl,
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
    List<ChatThread>? listThreads,
    Future<ChatThread?> Function()? loadDetail,
  }) {
    final router = GoRouter(
      initialLocation: '/sales/request-1',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            key: Key('home-shell'),
            body: Text('Solicitudes'),
            bottomNavigationBar: SizedBox(
              key: Key('main-menu'),
              height: 80,
            ),
          ),
        ),
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
            threads: listThreads ?? threads,
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
        requestDetailProvider((requestId: 'request-1', role: role))
            .overrideWith((ref) async {
          if (loadDetail != null) return loadDetail();
          for (final candidate in threads) {
            if (candidate.id == 'request-1') return candidate;
          }
          return null;
        }),
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
    expect(
      find.text('Puede haber expirado, sido cerrada o ya no estar disponible.'),
      findsOneWidget,
    );
    expect(find.text('Volver a solicitudes'), findsOneWidget);
    expect(
      tester
          .getSize(
            find.widgetWithText(OutlinedButton, 'Volver a solicitudes'),
          )
          .height,
      greaterThanOrEqualTo(48),
    );
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

  testWidgets('loads a new request detail independently from a stale list',
      (tester) async {
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [thread('request-1')],
        listThreads: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(find.text('Solicitud no disponible'), findsNothing);
  });

  testWidgets('request detail exposes loading before rendering data',
      (tester) async {
    final repository = _MockChatRepository();
    final completer = Completer<ChatThread?>();
    final request = thread('request-1');

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [request],
        loadDetail: () => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('request-detail-loading')), findsOneWidget);

    completer.complete(request);
    await tester.pumpAndSettle();

    expect(find.text('Toyota Corolla'), findsOneWidget);
  });

  testWidgets('missing deep link returns to the requests tab with its menu',
      (tester) async {
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(repository: repository, threads: const []),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a solicitudes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-shell')), findsOneWidget);
    expect(find.byKey(const Key('main-menu')), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(const Key('home-shell'))),
    );
    expect(container.read(homeTabProvider), MainNavigationTab.requests);
  });

  testWidgets('request detail error keeps a retry path', (tester) async {
    final repository = _MockChatRepository();
    var attempts = 0;
    final request = thread('request-1');

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [request],
        loadDetail: () async {
          attempts += 1;
          if (attempts == 1) throw Exception('network');
          return request;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No pudimos cargar la solicitud'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Toyota Corolla'), findsOneWidget);
    expect(attempts, 2);
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

  testWidgets('existing inquiry continues chat and never looks quoted',
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
            hasOffer: true,
            isInquiry: true,
            matchState: 'INQUIRING',
            offerStatus: 'INQUIRY',
            conversationId: 'conversation-1',
          ),
        ],
        textScaler: const TextScaler.linear(2),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CONTINUAR CONSULTA'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('continue-inquiry-button'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.textContaining('COTIZACIÓN ENVIADA'), findsNothing);
    expect(find.textContaining('Ya enviaste una cotización'), findsNothing);
    expect(find.text('INICIAR CHAT CON EL CLIENTE'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(
      find.byKey(const Key('continue-inquiry-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-inquiry-button')));
    await tester.pumpAndSettle();

    expect(find.text('Chat abierto'), findsOneWidget);
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

  testWidgets('formal quote keeps its quoted confirmation', (tester) async {
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [
          thread(
            'request-1',
            hasOffer: true,
            matchState: 'QUOTED',
            offerStatus: 'SENT',
            offerPrice: 125,
            conversationId: 'conversation-1',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('COTIZACIÓN ENVIADA (\$125.00)'), findsOneWidget);
    expect(find.text('CONTINUAR CONSULTA'), findsNothing);
  });

  testWidgets('does not show a generic car when the request has no photo',
      (tester) async {
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(repository: repository, threads: [thread('request-1')]),
    );
    await tester.pumpAndSettle();

    expect(
      find.image(const AssetImage('assets/images/header_car.png')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('request-no-photo-background')),
      findsOneWidget,
    );
  });

  testWidgets('shows only the photo uploaded with the request', (tester) async {
    const photoUrl = 'https://example.com/request-photo.jpg';
    final repository = _MockChatRepository();

    await tester.pumpWidget(
      subject(
        repository: repository,
        threads: [thread('request-1', fotoUrl: photoUrl)],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.image(const NetworkImage(photoUrl)), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/images/header_car.png')),
      findsNothing,
    );
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
    expect(find.text('Mejor precio'), findsOneWidget);
    expect(find.text('Más cercanos'), findsOneWidget);
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
