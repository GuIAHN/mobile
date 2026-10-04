import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/consumer_purchase.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/purchases_result.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/pages/consumer_purchases_page.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/widgets/consumer_purchase_card.dart';
import 'package:guiautomotriz_mobile/shared/widgets/skeleton_loader.dart';
import 'package:guiautomotriz_mobile/shared/widgets/status_filter_selector.dart';

void main() {
  testWidgets('purchase card presents catch-all path in text and semantics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumerPurchaseCard(
            purchase: ConsumerPurchase(
              id: 'purchase-catch-all',
              vehicleName: 'Toyota Corolla',
              storeName: 'Repuestos Central',
              status: PurchaseStatus.bought,
              lastActivityAt: DateTime.utc(2026, 9, 3),
              partName: 'Nombre administrativo variable',
              subcategoryIsCatchAll: true,
              categoryName: 'Frenos',
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Frenos › No sé cuál exactamente'),
      findsOneWidget,
    );
    expect(find.text('Nombre administrativo variable'), findsNothing);
    expect(
      find.bySemanticsLabel(
        RegExp(r'Compra de Frenos › No sé cuál exactamente'),
      ),
      findsOneWidget,
    );
  }, semanticsEnabled: true);

  testWidgets('renders loading, safe error, and empty states', (tester) async {
    final pending = Completer<PurchasesResult>();

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('loading-purchases'),
        overrides: [
          consumerPurchasesProvider.overrideWith((ref) => pending.future),
        ],
        child: const MaterialApp(home: ConsumerPurchasesPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(ThreadCardSkeleton), findsAtLeastNWidgets(3));

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('error-purchases'),
        overrides: [
          consumerPurchasesProvider.overrideWith(
            (ref) => Future.error(Exception('detalle interno sensible')),
          ),
        ],
        child: const MaterialApp(home: ConsumerPurchasesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus compras'), findsOneWidget);
    expect(find.textContaining('detalle interno sensible'), findsNothing);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('empty-purchases'),
        overrides: [
          consumerPurchasesProvider.overrideWith(
            (ref) async => const PurchasesResult(purchases: []),
          ),
        ],
        child: const MaterialApp(home: ConsumerPurchasesPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no tienes compras'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data state supports small screens and enlarged text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final purchase = ConsumerPurchase(
      id: 'purchase-responsive',
      vehicleName: 'Ferrari 308',
      storeName: 'Multirepuestos El Pana (Tienda)',
      status: PurchaseStatus.delivered,
      lastActivityAt: DateTime.utc(2026, 8, 31),
      partName: 'Pastillas de Frenos',
      price: 32,
      conversationId: 'conversation-review',
      needsReview: true,
      canReview: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consumerPurchasesProvider.overrideWith(
            (ref) async => PurchasesResult(
              purchases: [purchase],
              counts: const {'all': 1, 'delivered': 1},
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 34),
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const ConsumerPurchasesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final search = find.byKey(const Key('request-search-bar'));
    final filter = find.byKey(const Key('consumer-purchase-filter-group'));
    final review = find.byKey(const Key('consumer-purchase-review-action'));
    expect(tester.getSize(search).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(filter).height, inInclusiveRange(48, 100));
    expect(tester.getSize(review).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(review).width, greaterThan(200));
    expect(find.text('Multirepuestos El Pana (Tienda)'), findsOneWidget);
    expect(
      find.byType(AppStatusFilterSelector<PurchaseFilter>),
      findsOneWidget,
    );
    await tester.tap(filter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('status-filter-list')), findsOneWidget);
    final sheetSurface = find.byKey(
      const Key('status-filter-sheet-surface'),
    );
    expect(
      tester.getBottomRight(sheetSurface).dy,
      tester.getBottomRight(find.byType(BottomSheet).last).dy,
    );
    expect(find.byKey(const Key('purchase-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('purchase-filter-delivered')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reviewed purchase exposes only the read action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConsumerPurchaseCard(
            purchase: ConsumerPurchase(
              id: 'reviewed-purchase',
              vehicleName: 'Toyota Corolla',
              storeName: 'Repuestos Central',
              status: PurchaseStatus.delivered,
              lastActivityAt: DateTime.utc(2026, 8, 14),
              partName: 'Amortiguadores',
              price: 120,
              hasReviewed: true,
              reviewTargetId: 'store-user-1',
            ),
            onReview: () => pressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Dejar reseña'), findsNothing);
    expect(find.text('Ver reseña'), findsOneWidget);
    await tester.tap(find.byKey(const Key('consumer-purchase-review-action')));
    expect(pressed, isTrue);
  });

  testWidgets(
      'cancelled purchase opens the canonical store detail without chat or type fallback',
      (tester) async {
    final purchase = ConsumerPurchase(
      id: 'purchase-1',
      vehicleName: 'Ferrari 308',
      storeName: 'Multirepuestos El Pana',
      storeId: 'store-1',
      status: PurchaseStatus.cancelled,
      lastActivityAt: DateTime.utc(2026, 8, 31),
      partName: 'Pastillas de Frenos',
      price: 32,
      conversationId: 'conversation-cancelled',
    );
    final router = GoRouter(
      initialLocation: RouteNames.purchases,
      routes: [
        GoRoute(
          path: RouteNames.purchases,
          builder: (_, __) => const ConsumerPurchasesPage(),
        ),
        GoRoute(
          path: RouteNames.storeDetail,
          builder: (_, state) => Scaffold(
            body: Text(
              'Detalle tienda ${state.pathParameters['id']} '
              '${state.uri.queryParameters['reviewConversationId']}',
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.workshopDetail,
          builder: (_, state) => Scaffold(
            body: Text('Detalle taller ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consumerPurchasesProvider.overrideWith(
            (ref) async => PurchasesResult(
              purchases: [purchase],
              counts: const {'all': 1, 'cancelled': 1},
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dejar reseña'), findsOneWidget);
    expect(find.textContaining('Chat'), findsNothing);
    final reviewLabel = tester.widget<Text>(find.text('Dejar reseña'));
    expect(reviewLabel.maxLines, 1);
    expect(reviewLabel.softWrap, isFalse);

    await tester.tap(find.text('Dejar reseña'));
    await tester.pumpAndSettle();

    expect(
      find.text('Detalle tienda store-1 conversation-cancelled'),
      findsOneWidget,
    );
    expect(find.textContaining('Detalle taller'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
