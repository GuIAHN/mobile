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
        total: 1,
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    required UserRole role,
    required Widget page,
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
            (ref) async => resultFor(storeRequest),
          ),
        ],
        child: MaterialApp(home: page),
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
    expect(find.text('Con ofertas'), findsOneWidget);
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
