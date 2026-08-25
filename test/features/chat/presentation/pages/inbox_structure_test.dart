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
            ),
            child: child!,
          ),
          home: page,
        ),
      ),
    );
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
    expect(find.text('Cotizadas'), findsOneWidget);
    expect(find.text('Compradas'), findsOneWidget);
    expect(find.text('Canceladas'), findsOneWidget);
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

    await tester.tap(find.text('Cotizadas'));
    await tester.pump();
    expect(container.read(consumerStatusFilterProvider), 'WITH_OFFER');

    await tester.tap(find.text('Compradas'));
    await tester.pump();
    expect(container.read(consumerStatusFilterProvider), 'BOUGHT');

    await tester.tap(find.text('Canceladas'));
    await tester.pump();
    expect(container.read(consumerStatusFilterProvider), 'CANCELLED');
  });

  testWidgets('Compras exposes all four filters without horizontal scrolling',
      (tester) async {
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

    final active = tester.getCenter(find.text('Activas'));
    final quoted = tester.getCenter(find.text('Cotizadas'));
    final bought = tester.getCenter(find.text('Compradas'));
    final cancelled = tester.getCenter(find.text('Canceladas'));
    expect(active.dy, closeTo(quoted.dy, 1));
    expect(quoted.dy, closeTo(bought.dy, 1));
    expect(bought.dy, closeTo(cancelled.dy, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('store Chats and Ventas are independent sections',
      (tester) async {
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
    expect(find.text('Cotizadas'), findsOneWidget);
    expect(find.text('Canceladas'), findsOneWidget);
    expect(find.text('Entregadas'), findsOneWidget);
    expect(find.text('Consultas'), findsNothing);
    expect(find.text('Declinadas'), findsNothing);
    expect(find.text('Vendidas'), findsNothing);
    expect(find.text('Descartadas'), findsNothing);
    expect(find.text('Todas'), findsNothing);
  });

  testWidgets('Ventas exposes all four filters without horizontal scrolling',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpPage(
      tester,
      role: UserRole.store,
      page: const StoreSalesPage(),
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

    final pending = tester.getCenter(find.text('Pendientes'));
    final quoted = tester.getCenter(find.text('Cotizadas'));
    final cancelled = tester.getCenter(find.text('Canceladas'));
    final delivered = tester.getCenter(find.text('Entregadas'));

    expect(pending.dy, closeTo(quoted.dy, 1));
    expect(cancelled.dy, closeTo(delivered.dy, 1));
    expect(pending.dy, closeTo(cancelled.dy, 1));

    final deliveredTarget = find
        .ancestor(
          of: find.text('Entregadas'),
          matching: find.byType(InkWell),
        )
        .first;
    expect(tester.getSize(deliveredTarget).height, greaterThanOrEqualTo(48));
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

  testWidgets('store keeps cancelled and delivered requests until expiration',
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
          matchState: status == 'QUOTED' ? 'QUOTED' : 'PENDING',
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

    await tester.tap(find.text('Canceladas'));
    await tester.pump();
    expect(container.read(storeStatusFilterProvider), 'CANCELLED');
    expect(find.text('Cancelada vigente'), findsOneWidget);
    expect(find.text('Cancelada expirada'), findsNothing);

    await tester.tap(find.text('Entregadas'));
    await tester.pump();
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
