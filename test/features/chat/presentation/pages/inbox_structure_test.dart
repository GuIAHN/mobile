import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/conversations_inbox_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/consumer_requests_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/store_sales_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/store_requests_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final conversation = ChatConversation(
    id: 'conversation-1',
    threadId: 'request-1',
    participantName: 'Repuestos Central',
    lastMessage: 'La pieza está disponible',
    unreadCount: 2,
    lastMessageAt: DateTime.utc(2026, 8, 14),
    offerStatus: 'BOUGHT',
    hasQuote: true,
    price: 125,
  );
  final consumerRequest = ChatThread(
    id: 'request-1',
    title: 'Motor BMW N55',
    requestType: ServiceType.spareParts,
    unreadCount: 0,
    conversationCount: 1,
    lastActivityAt: DateTime.utc(2026, 8, 14),
    totalOffersCount: 1,
    subcategory: 'Frenos',
    bestOfferPrice: 125,
    bestOfferStoreName: 'Repuestos Central',
  );
  final storeRequest = ChatThread(
    id: 'request-2',
    title: 'Bomba de gasolina',
    requestType: ServiceType.spareParts,
    unreadCount: 0,
    conversationCount: 0,
    lastActivityAt: DateTime.utc(2026, 8, 14),
    clientName: 'Carlos',
    searchMatchId: 'match-1',
    matchState: 'PENDING',
  );
  ChatThreadsResult resultFor(ChatThread thread) => ChatThreadsResult(
        threads: [thread],
        counts: const {'all': 1, 'open': 1, 'closed': 0},
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    required UserRole role,
    required Widget page,
    ChatThreadsResult? storeResult,
    List<ChatConversation>? conversations,
    List<String>? requestedStoreStatuses,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRoleProvider.overrideWithValue(role),
          myConversationsProvider.overrideWith(
            (ref) async => conversations ?? [conversation],
          ),
          consumerRequestsProvider.overrideWith(
            (ref) async => resultFor(consumerRequest),
          ),
          storeSalesRequestsProvider.overrideWith(
            (ref) async => storeResult ?? resultFor(storeRequest),
          ),
          storeRequestsByStatusProvider.overrideWith(
            (ref, status) async {
              requestedStoreStatuses?.add(status);
              return storeResult ?? resultFor(storeRequest);
            },
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openStatusSelector(WidgetTester tester, Key selectorKey) async {
    await tester.tap(find.byKey(selectorKey));
    await tester.pumpAndSettle();
  }

  Future<void> selectStatus(
    WidgetTester tester, {
    required Key selectorKey,
    required String status,
  }) async {
    await openStatusSelector(tester, selectorKey);
    await tester.tap(find.byKey(Key('status-filter-$status')));
    await tester.pumpAndSettle();
  }

  testWidgets('store requests use the backend TO_ANSWER filter',
      (tester) async {
    final requestedStatuses = <String>[];

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      requestedStoreStatuses: requestedStatuses,
    );

    expect(requestedStatuses, contains('TO_ANSWER'));
    expect(requestedStatuses, isNot(contains('PENDING')));
  });

  testWidgets('store requests show the backend toDeliver count immediately',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      storeResult: ChatThreadsResult(
        threads: [storeRequest],
        counts: const {
          'toAnswer': 1,
          'quoted': 0,
          'toDeliver': 3,
        },
      ),
    );

    await openStatusSelector(
      tester,
      const Key('store-requests-filter-group'),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('status-filter-bought')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('consumer Chats contains conversations, not requests',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConversationsInboxPage(),
    );

    expect(find.text('Chats'), findsNothing);
    expect(find.text('Conversaciones con tiendas'), findsNothing);
    expect(find.text('Repuestos Central'), findsOneWidget);
    expect(find.text('Motor BMW N55'), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(
          r'Chat con Repuestos Central, comprada, \$125, '
          r'2 mensajes sin leer, último mensaje: La pieza está disponible',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Chats hides delivered requests after the review was submitted',
      (tester) async {
    final deliveredAndReviewed = ChatConversation(
      id: 'conversation-reviewed',
      threadId: 'request-reviewed',
      participantName: 'Tienda reseñada',
      lastMessage: 'Pedido entregado',
      unreadCount: 0,
      lastMessageAt: DateTime.utc(2026, 8, 14),
      offerStatus: 'DELIVERED',
      hasReviewed: true,
    );
    final deliveredPendingReview = ChatConversation(
      id: 'conversation-pending-review',
      threadId: 'request-pending-review',
      participantName: 'Tienda pendiente',
      lastMessage: 'Pedido entregado',
      unreadCount: 0,
      lastMessageAt: DateTime.utc(2026, 8, 14),
      offerStatus: 'DELIVERED',
      hasReviewed: false,
    );

    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConversationsInboxPage(),
      conversations: [deliveredAndReviewed, deliveredPendingReview],
    );

    expect(find.text('Tienda reseñada'), findsNothing);
    expect(find.text('Tienda pendiente'), findsOneWidget);
  });

  testWidgets('consumer Solicitudes exposes only the three approved filters',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConsumerRequestsPage(),
    );

    expect(find.text('Compras'), findsNothing);
    expect(find.text('Administra tus solicitudes y compara ofertas'),
        findsNothing);
    expect(find.text('Motor BMW N55'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Cotizadas'), findsNothing);
    expect(find.text('Compradas'), findsNothing);
    expect(find.text('Canceladas'), findsNothing);
    expect(find.text('Cerradas'), findsNothing);
    expect(
      tester
          .getCenter(
            find.byKey(const Key('consumer-request-filter-group')),
          )
          .dx,
      closeTo(tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
          0.5),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConsumerRequestsPage)),
    );
    expect(container.read(consumerStatusFilterProvider), 'ALL');

    await openStatusSelector(
      tester,
      const Key('consumer-request-filter-group'),
    );
    expect(find.text('Filtrar por estado'), findsOneWidget);
    expect(find.byKey(const Key('status-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-inquiring')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-cancelled')), findsNothing);

    await tester.tap(find.byKey(const Key('status-filter-quoted')));
    await tester.pumpAndSettle();
    expect(container.read(consumerStatusFilterProvider), 'WITH_OFFER');

    await selectStatus(
      tester,
      selectorKey: const Key('consumer-request-filter-group'),
      status: 'inquiring',
    );
    expect(container.read(consumerStatusFilterProvider), 'ALL');
  });

  testWidgets('Solicitudes selector stays compact with large text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConsumerRequestsPage(),
      textScale: 2,
    );

    final group = find.byKey(const Key('consumer-request-filter-group'));
    expect(group, findsOneWidget);
    expect(
      find.ancestor(
        of: group,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(tester.getSize(group).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(group).height, lessThan(100));

    await openStatusSelector(
      tester,
      const Key('consumer-request-filter-group'),
    );
    expect(find.byKey(const Key('status-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-inquiring')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('store Chats and Ventas are independent sections',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const ConversationsInboxPage(),
    );

    expect(find.text('Chats'), findsNothing);
    expect(find.text('Conversaciones con tus clientes'), findsNothing);
    expect(find.text('Repuestos Central'), findsOneWidget);
    expect(find.text('Bomba de gasolina'), findsNothing);

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
    );

    expect(find.text('Ventas'), findsNothing);
    expect(find.text('Cotiza solicitudes y da seguimiento a tus ventas'),
        findsNothing);
    expect(find.text('Bomba de gasolina'), findsOneWidget);
    expect(find.text('Por responder'), findsAtLeastNWidgets(1));
    expect(find.text('Cotizada'), findsNothing);
    expect(find.text('Compradas'), findsNothing);
    expect(find.text('Canceladas'), findsNothing);
    expect(find.text('Entregadas'), findsNothing);
    expect(find.text('Consultas'), findsNothing);
    expect(find.text('Declinadas'), findsNothing);
    expect(find.text('Vendidas'), findsNothing);
    expect(find.text('Descartadas'), findsNothing);
    expect(find.text('Todas'), findsNothing);

    await openStatusSelector(
      tester,
      const Key('store-requests-filter-group'),
    );
    expect(find.byKey(const Key('status-filter-pending')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-bought')), findsOneWidget);
    expect(find.text('Por entregar'), findsOneWidget);
    expect(find.text('Compradas'), findsNothing);
    expect(find.byKey(const Key('status-filter-delivered')), findsNothing);
    expect(find.byKey(const Key('status-filter-cancelled')), findsNothing);
  });

  testWidgets('Solicitudes selector exposes three touch-friendly states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      textScale: 2,
      disableAnimations: true,
    );

    final group = find.byKey(const Key('store-requests-filter-group'));
    expect(group, findsOneWidget);
    expect(
      find.ancestor(
        of: group,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(tester.getSize(group).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(group).height, lessThan(100));

    await openStatusSelector(tester, const Key('store-requests-filter-group'));
    final boughtTarget = find.byKey(const Key('status-filter-bought'));
    expect(boughtTarget, findsOneWidget);
    expect(tester.getSize(boughtTarget).height, greaterThanOrEqualTo(48));
    expect(find.byKey(const Key('status-filter-delivered')), findsNothing);
    expect(find.byKey(const Key('status-filter-cancelled')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('price-less inquiries remain visible in store Pendientes',
      (tester) async {
    final inquiry = ChatThread(
      id: 'request-inquiry',
      title: 'Consulta por alternador',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 1,
      lastActivityAt: DateTime.utc(2026, 8, 14),
      clientName: 'Ana',
      searchMatchId: 'match-inquiry',
      matchState: 'INQUIRING',
      isInquiry: true,
      hasOffer: true,
      conversationId: 'conversation-inquiry',
    );

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      storeResult: ChatThreadsResult(
        threads: [storeRequest, inquiry],
        counts: const {
          'all': 2,
          'pending': 1,
          'inquiring': 1,
        },
      ),
    );

    expect(find.text('Bomba de gasolina'), findsOneWidget);
    expect(find.text('Consulta por alternador'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('expired requests are hidden from store Pendientes',
      (tester) async {
    final expiredByFlag = ChatThread(
      id: 'expired-by-flag',
      title: 'Solicitud expirada por estado',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 14),
      matchState: 'PENDING',
      isExpired: true,
    );
    final expiredByDate = ChatThread(
      id: 'expired-by-date',
      title: 'Solicitud expirada por fecha',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 14),
      matchState: 'INQUIRING',
      expiresAt: DateTime.utc(2020),
    );

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      storeResult: ChatThreadsResult(
        threads: [storeRequest, expiredByFlag, expiredByDate],
        counts: const {'pending': 2, 'inquiring': 1},
      ),
    );

    expect(find.text('Bomba de gasolina'), findsOneWidget);
    expect(find.text('Solicitud expirada por estado'), findsNothing);
    expect(find.text('Solicitud expirada por fecha'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('closed requests are hidden from store Pendientes',
      (tester) async {
    final boughtElsewhere = ChatThread(
      id: 'closed-after-other-purchase',
      title: 'Comprada en otra tienda',
      requestType: ServiceType.spareParts,
      unreadCount: 0,
      conversationCount: 0,
      lastActivityAt: DateTime.utc(2026, 8, 14),
      matchState: 'PENDING',
      isOpen: false,
    );

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreRequestsPage(),
      storeResult: ChatThreadsResult(
        threads: [storeRequest, boughtElsewhere],
        counts: const {'pending': 2},
      ),
    );

    expect(find.text('Bomba de gasolina'), findsOneWidget);
    expect(find.text('Comprada en otra tienda'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
      'Mis ventas exposes delivered and cancelled sales including history',
      (tester) async {
    ChatThread sale({
      required String id,
      required String title,
      required String status,
      required bool isExpired,
    }) =>
        ChatThread(
          id: id,
          title: title,
          requestType: ServiceType.spareParts,
          unreadCount: 0,
          conversationCount: 0,
          lastActivityAt: DateTime.utc(2026, 8, 14),
          offerStatus: status,
          matchState: status,
          isExpired: isExpired,
        );

    final result = ChatThreadsResult(
      threads: [
        sale(
          id: 'cancelled-current',
          title: 'Cancelada vigente',
          status: 'CANCELLED',
          isExpired: false,
        ),
        sale(
          id: 'cancelled-expired',
          title: 'Cancelada expirada',
          status: 'CANCELLED',
          isExpired: true,
        ),
        sale(
          id: 'delivered-current',
          title: 'Entregada vigente',
          status: 'DELIVERED',
          isExpired: false,
        ),
        sale(
          id: 'delivered-expired',
          title: 'Entregada expirada',
          status: 'DELIVERED',
          isExpired: true,
        ),
      ],
      counts: const {'cancelled': 2, 'delivered': 2},
    );

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreSalesPage(),
      storeResult: result,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(StoreSalesPage)),
    );

    expect(find.text('Entregada vigente'), findsOneWidget);
    expect(find.text('Entregada expirada'), findsOneWidget);

    await selectStatus(
      tester,
      selectorKey: const Key('store-sales-filter-group'),
      status: 'cancelled',
    );
    expect(container.read(storeStatusFilterProvider), 'CANCELLED');
    expect(find.text('Cancelada vigente'), findsOneWidget);
    expect(find.text('Cancelada expirada'), findsOneWidget);

    await selectStatus(
      tester,
      selectorKey: const Key('store-sales-filter-group'),
      status: 'delivered',
    );
    expect(container.read(storeStatusFilterProvider), 'DELIVERED');
    expect(find.text('Entregada vigente'), findsOneWidget);
    expect(find.text('Entregada expirada'), findsOneWidget);
  });

  testWidgets('Ventas search field does not draw an inner border',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreSalesPage(),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    final decoration = field.decoration!;

    expect(decoration.border, InputBorder.none);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(decoration.disabledBorder, InputBorder.none);
    expect(decoration.errorBorder, InputBorder.none);
    expect(decoration.focusedErrorBorder, InputBorder.none);
  });

  testWidgets('Chats starts with a compact search control', (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConversationsInboxPage(),
    );

    final chatsSearch = find.byKey(const Key('conversations-search-bar'));
    expect(tester.getTopLeft(chatsSearch).dy, 14);
    expect(tester.getSize(chatsSearch).height, greaterThanOrEqualTo(48));
  });

  testWidgets('Chats search filters only the conversation list',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConversationsInboxPage(),
    );

    await tester.enterText(find.byType(TextField), 'otra tienda');
    await tester.pump();

    expect(find.text('Repuestos Central'), findsNothing);
    expect(find.text('Sin resultados'), findsOneWidget);
  });
}
