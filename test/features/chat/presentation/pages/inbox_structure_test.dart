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
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/mis_compras_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/store_sales_page.dart';
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
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRoleProvider.overrideWithValue(role),
          myConversationsProvider.overrideWith((ref) async => [conversation]),
          consumerRequestsProvider.overrideWith(
            (ref) async => resultFor(consumerRequest),
          ),
          storeSalesRequestsProvider.overrideWith(
            (ref) async => storeResult ?? resultFor(storeRequest),
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

  testWidgets('consumer Compras contains the complete request management',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConsumerPurchasesPage(),
    );

    expect(find.text('Compras'), findsNothing);
    expect(find.text('Administra tus solicitudes y compara ofertas'),
        findsNothing);
    expect(find.text('Motor BMW N55'), findsOneWidget);
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Cotizadas'), findsNothing);
    expect(find.text('Compradas'), findsNothing);
    expect(find.text('Canceladas'), findsNothing);
    expect(find.text('Todas'), findsNothing);
    expect(find.text('Cerradas'), findsNothing);
    expect(
      tester
          .getCenter(
            find.byKey(const Key('consumer-purchase-filter-group')),
          )
          .dx,
      closeTo(tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
          0.5),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ConsumerPurchasesPage)),
    );
    expect(container.read(consumerStatusFilterProvider), 'OPEN');

    await openStatusSelector(
      tester,
      const Key('consumer-purchase-filter-group'),
    );
    expect(find.text('Filtrar por estado'), findsOneWidget);
    expect(find.byKey(const Key('status-filter-active')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-bought')), findsOneWidget);
    expect(
      find.byKey(
        const Key('status-filter-cancelled'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('status-filter-quoted')));
    await tester.pumpAndSettle();
    expect(container.read(consumerStatusFilterProvider), 'WITH_OFFER');

    await selectStatus(
      tester,
      selectorKey: const Key('consumer-purchase-filter-group'),
      status: 'bought',
    );
    expect(container.read(consumerStatusFilterProvider), 'BOUGHT');

    await selectStatus(
      tester,
      selectorKey: const Key('consumer-purchase-filter-group'),
      status: 'cancelled',
    );
    expect(container.read(consumerStatusFilterProvider), 'CANCELLED');
  });

  testWidgets('Compras selector stays compact with large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConsumerPurchasesPage(),
      textScale: 2,
    );

    final group = find.byKey(const Key('consumer-purchase-filter-group'));
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
      const Key('consumer-purchase-filter-group'),
    );
    expect(find.byKey(const Key('status-filter-active')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-bought')), findsOneWidget);
    expect(
      find.byKey(
        const Key('status-filter-cancelled'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
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
      page: const StoreSalesPage(),
    );

    expect(find.text('Ventas'), findsNothing);
    expect(find.text('Cotiza solicitudes y da seguimiento a tus ventas'),
        findsNothing);
    expect(find.text('Bomba de gasolina'), findsOneWidget);
    expect(find.text('Pendientes'), findsAtLeastNWidgets(1));
    expect(find.text('Cotizadas'), findsNothing);
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
      const Key('store-sales-filter-group'),
    );
    expect(find.byKey(const Key('status-filter-pending')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-quoted')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-bought')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-delivered')), findsOneWidget);
    expect(find.byKey(const Key('status-filter-cancelled')), findsOneWidget);
  });

  testWidgets('Ventas selector exposes five touch-friendly states',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreSalesPage(),
      textScale: 2,
      disableAnimations: true,
    );

    final group = find.byKey(const Key('store-sales-filter-group'));
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

    await openStatusSelector(tester, const Key('store-sales-filter-group'));
    final boughtTarget = find.byKey(const Key('status-filter-bought'));
    expect(boughtTarget, findsOneWidget);
    expect(tester.getSize(boughtTarget).height, greaterThanOrEqualTo(48));
    await tester.scrollUntilVisible(
      find.byKey(const Key('status-filter-delivered')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('status-filter-delivered')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('status-filter-cancelled')),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const Key('status-filter-cancelled')), findsOneWidget);
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
      page: const StoreSalesPage(),
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
      page: const StoreSalesPage(),
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

  testWidgets(
      'store exposes bought sales and keeps terminal sales until expiration',
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
          id: 'bought-current',
          title: 'Comprada por entregar',
          status: 'BOUGHT',
          isExpired: false,
        ),
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
      counts: const {'bought': 1, 'cancelled': 2, 'delivered': 2},
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

    await selectStatus(
      tester,
      selectorKey: const Key('store-sales-filter-group'),
      status: 'bought',
    );
    expect(container.read(storeStatusFilterProvider), 'BOUGHT');
    expect(find.text('Comprada por entregar'), findsOneWidget);

    await selectStatus(
      tester,
      selectorKey: const Key('store-sales-filter-group'),
      status: 'cancelled',
    );
    expect(container.read(storeStatusFilterProvider), 'CANCELLED');
    expect(find.text('Cancelada vigente'), findsOneWidget);
    expect(find.text('Cancelada expirada'), findsNothing);

    await selectStatus(
      tester,
      selectorKey: const Key('store-sales-filter-group'),
      status: 'delivered',
    );
    expect(container.read(storeStatusFilterProvider), 'DELIVERED');
    expect(find.text('Entregada vigente'), findsOneWidget);
    expect(find.text('Entregada expirada'), findsNothing);
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

  testWidgets('Chats and Compras start with compact search controls',
      (tester) async {
    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConversationsInboxPage(),
    );

    final chatsSearch = find.byKey(const Key('conversations-search-bar'));
    expect(tester.getTopLeft(chatsSearch).dy, 14);
    expect(tester.getSize(chatsSearch).height, greaterThanOrEqualTo(48));

    await pumpPage(
      tester,
      role: UserRole.consumer,
      page: const ConsumerPurchasesPage(),
    );

    final purchasesSearch = find.byKey(const Key('request-search-bar'));
    expect(tester.getTopLeft(purchasesSearch).dy, 14);
    expect(tester.getSize(purchasesSearch).height, greaterThanOrEqualTo(48));
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
