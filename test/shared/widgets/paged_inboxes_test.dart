import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/entities/paged_result.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/service_type.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/user_role.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_conversation.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_thread.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/entities/chat_threads_result.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/usecases/get_chat_threads_usecase.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/chat_inbox_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/pages/conversations_inbox_page.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/consumer_purchase.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/purchases_result.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/usecases/get_consumer_purchases_usecase.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/pages/consumer_purchases_page.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/usecases/get_reviews_usecase.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/pages/provider_reviews_page.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/core/providers/current_user_provider.dart';
import 'package:guiautomotriz_mobile/core/storage/secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _Requests extends Mock implements GetChatThreadsUseCase {}

class _Purchases extends Mock implements GetConsumerPurchasesUseCase {}

class _Reviews extends Mock implements GetReviewsUseCase {}

class _Chat extends Mock implements ChatRepository {}

class _Storage extends Mock implements SecureStorage {}

void main() {
  setUpAll(() async {
    registerFallbackValue(PurchaseFilter.all);
    await initializeDateFormatting('es');
  });
  final date = DateTime.utc(2026, 11, 3);
  final threads = List.generate(
      43,
      (i) => ChatThread(
          id: 'r$i',
          title: 'Vehículo $i',
          requestType: ServiceType.spareParts,
          unreadCount: 0,
          conversationCount: 0,
          createdAt: date.subtract(Duration(minutes: i)),
          lastActivityAt: date,
          matchState: 'PENDING',
          offerStatus: 'DELIVERED',
          subcategory: 'Pieza $i'));
  final purchases = List.generate(
      43,
      (i) => ConsumerPurchase(
          id: 'p$i',
          vehicleName: 'Vehículo $i',
          storeName: 'Tienda $i',
          status: PurchaseStatus.bought,
          lastActivityAt: date));
  final reviews = List.generate(
      43,
      (i) => Review(
          id: 'v$i',
          authorId: 'a$i',
          targetId: 'target',
          rating: 5,
          createdAt: date,
          authorName: 'Autor $i'));
  final conversations = List.generate(
      43,
      (i) => ChatConversation(
          id: 'c$i',
          threadId: 'r$i',
          participantName: 'Tienda $i',
          lastMessage: 'Mensaje $i',
          unreadCount: 0,
          lastMessageIsFromMe: false,
          lastMessageAt: date.subtract(Duration(minutes: i))));

  List<T> batch<T>(List<T> items, int page) =>
      items.skip((page - 1) * 20).take(20).toList();

  Future<ProviderContainer> pump(WidgetTester tester, String kind,
      {double textScale = 1}) async {
    final requests = _Requests();
    final buys = _Purchases();
    final ratings = _Reviews();
    final chat = _Chat();
    final storage = _Storage();
    when(() => requests(
        role: any(named: 'role'),
        statusFilter: any(named: 'statusFilter'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'))).thenAnswer((call) async {
      final page = call.namedArguments[#page] as int;
      return Right(ChatThreadsResult(
          threads: batch(threads, page),
          page: page,
          total: 43,
          counts: const {'all': 43, 'pending': 43, 'delivered': 43}));
    });
    when(() => buys(
        filter: any(named: 'filter'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'))).thenAnswer((call) async {
      final page = call.namedArguments[#page] as int;
      return Right(PurchasesResult(
          purchases: batch(purchases, page), page: page, total: 43));
    });
    when(() => ratings('target',
        page: any(named: 'page'),
        limit: any(named: 'limit'))).thenAnswer((call) async {
      final page = call.namedArguments[#page] as int;
      return Right(
          PaginatedReviews(items: batch(reviews, page), page: page, total: 43));
    });
    when(() => chat.getMyConversations(
            page: any(named: 'page'), pageSize: any(named: 'pageSize')))
        .thenAnswer((call) async =>
            Right(batch(conversations, call.namedArguments[#page] as int)));
    when(() => storage.hasHandledStoreReview(any()))
        .thenAnswer((_) async => false);
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(null),
      currentRoleProvider.overrideWithValue(
          kind.startsWith('store') ? UserRole.store : UserRole.consumer),
      secureStorageProvider.overrideWithValue(storage),
      chatRepositoryProvider.overrideWithValue(chat),
      getChatThreadsUseCaseProvider.overrideWithValue(requests),
      getConsumerPurchasesUseCaseProvider.overrideWithValue(buys),
      getReviewsUseCaseProvider.overrideWithValue(ratings),
      consumerRequestsProvider.overrideWith((ref) async => ChatThreadsResult(
          threads: batch(threads, 1).reversed.toList(), total: 43)),
      storeRequestsByStatusProvider.overrideWith((ref, status) async =>
          ChatThreadsResult(
              threads: batch(threads, 1).reversed.toList(),
              total: 43,
              counts: const {'all': 43, 'pending': 43, 'delivered': 43})),
      consumerPurchasesProvider.overrideWith((ref) async =>
          PurchasesResult(purchases: batch(purchases, 1), total: 43)),
      reviewsProvider.overrideWith((ref, id) async =>
          PaginatedReviews(items: batch(reviews, 1), total: 43)),
      myConversationsProvider.overrideWith(
          (ref) async => PagedResult(items: batch(conversations, 1))),
    ]);
    addTearDown(container.dispose);
    final page = switch (kind) {
      'requests' =>
        const RequestsInboxPage(mode: RequestInboxMode.consumerRequests),
      'storeRequests' =>
        const RequestsInboxPage(mode: RequestInboxMode.storeRequests),
      'storeSales' =>
        const RequestsInboxPage(mode: RequestInboxMode.storeSales),
      'purchases' => const ConsumerPurchasesPage(),
      'reviews' => const ProviderReviewsPage(targetId: 'target'),
      _ => const ConversationsInboxPage(),
    };
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(textScale),
                    disableAnimations: true,
                    padding: const EdgeInsets.only(top: 40, bottom: 34)),
                child: child!),
            home: page)));
    await tester.pumpAndSettle();
    return container;
  }

  for (final kind in [
    'requests',
    'storeRequests',
    'storeSales',
    'purchases',
    'reviews',
    'conversations'
  ]) {
    testWidgets('$kind scrolls beyond record 20 through all 43 records',
        (tester) async {
      await pump(tester, kind);
      final label = kind == 'reviews'
          ? 'Autor 42'
          : kind == 'conversations'
              ? 'Tienda 42'
              : 'Vehículo 42';
      await tester.scrollUntilVisible(find.text(label), 550,
          maxScrolls: 100,
          scrollable: find
              .descendant(
                  of: find.byType(ListView), matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 430.0]) {
    for (final kind in [
      'requests',
      'storeRequests',
      'storeSales',
      'purchases',
      'reviews',
      'conversations'
    ]) {
      testWidgets(
          '$kind fits width $width with 200 percent text and safe areas',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pump(tester, kind, textScale: 2);
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final kind in ['requests', 'purchases', 'conversations']) {
    testWidgets('$kind search reaches a match on page three', (tester) async {
      await pump(tester, kind);
      await tester.enterText(find.byType(TextField).first,
          kind == 'conversations' ? 'Tienda 42' : 'Vehículo 42');
      await tester.pumpAndSettle();
      expect(find.text(kind == 'conversations' ? 'Tienda 42' : 'Vehículo 42'),
          findsAtLeastNWidgets(1));
      expect(find.text('Sin resultados'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'requests display newest creation date first even when response is reversed',
      (tester) async {
    final container = await pump(tester, 'requests');
    final state =
        container.read(paginatedRequestsProvider('consumer')).requireValue;
    expect(state.items.first.id, 'r0');
    expect(tester.getTopLeft(find.text('Vehículo 0')).dy,
        lessThan(tester.getTopLeft(find.text('Vehículo 1')).dy));
  });
}
