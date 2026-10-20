import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/features/home/domain/entities/top_providers_result.dart';
import 'package:guiautomotriz_mobile/features/home/presentation/providers/home_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/purchases_result.dart';
import 'package:guiautomotriz_mobile/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/write_review_bottom_sheet.dart';

class _ReviewsRepository extends Mock implements ReviewsRepository {}

void main() {
  testWidgets(
      'publishes a new purchase review and refreshes purchases and reminders',
      (tester) async {
    final repository = _ReviewsRepository();
    final saved = Review(
        id: 'review-2',
        authorId: 'consumer',
        targetId: 'store-user',
        offerId: 'offer-2',
        rating: 5,
        createdAt: DateTime.utc(2026, 10, 18),
        authorName: 'Cliente');
    when(() => repository.getMyReview('store-user', offerId: 'offer-2'))
        .thenAnswer(
            (_) async => const Right(MyReviewStatus(hasReviewed: false)));
    when(() => repository.createReview(
        offerId: 'offer-2',
        rating: 5,
        comentario: 'Segunda compra')).thenAnswer((_) async => Right(saved));
    var purchasesLoads = 0;
    var pendingLoads = 0;
    var topProvidersLoads = 0;
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (_, __) => Consumer(builder: (context, ref, _) {
                ref.watch(consumerPurchasesProvider);
                ref.watch(pendingReviewsProvider);
                ref.watch(homeTopProvidersProvider);
                return Scaffold(
                    body: ElevatedButton(
                        onPressed: () => showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => const WriteReviewBottomSheet(
                                targetId: 'store-user',
                                offerId: 'offer-2',
                                providerName: 'Tienda',
                              ),
                            ),
                        child: const Text('Valorar segunda compra')));
              }))
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        reviewsRepositoryProvider.overrideWithValue(repository),
        homeTopProvidersProvider.overrideWith((ref) async {
          topProvidersLoads++;
          return const TopProvidersResult(mechanics: [], workshops: []);
        }),
        consumerPurchasesProvider.overrideWith((ref) async {
          purchasesLoads++;
          return const PurchasesResult(purchases: []);
        }),
        pendingReviewsProvider.overrideWith((ref) async {
          pendingLoads++;
          return [];
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(purchasesLoads, 1);
    expect(pendingLoads, 1);
    await tester.tap(find.text('Valorar segunda compra'));
    await tester.pumpAndSettle();
    expect(find.text('Editar valoración'), findsNothing);
    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.enterText(find.byType(TextFormField), 'Segunda compra');
    await tester.ensureVisible(find.text('PUBLICAR RESEÑA'));
    await tester.tap(find.text('PUBLICAR RESEÑA'));
    await tester.pumpAndSettle();
    expect(find.byType(WriteReviewBottomSheet), findsNothing);
    expect(purchasesLoads, 2);
    expect(pendingLoads, 2);
    expect(topProvidersLoads, 2);
    verify(() => repository.createReview(
        offerId: 'offer-2', rating: 5, comentario: 'Segunda compra')).called(1);
    verifyNever(() => repository.updateReview(any(),
        rating: any(named: 'rating'), comentario: any(named: 'comentario')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocks submission until stars are selected', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => const MyReviewStatus(hasReviewed: false),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WriteReviewBottomSheet(
              targetId: 'mechanic-user-1',
              providerName: 'Mecánico Centro',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.pump();
    button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('fits a small safe area with 200 percent text', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => const MyReviewStatus(hasReviewed: false),
          ),
        ],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              padding: EdgeInsets.only(bottom: 24),
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: WriteReviewBottomSheet(
                targetId: 'mechanic-user-1',
                providerName: 'Mecánico con un nombre bastante largo',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('PUBLICAR RESEÑA'), findsOneWidget);
  });

  testWidgets('shows an existing review in read-only mode', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => MyReviewStatus(
              hasReviewed: true,
              review: Review(
                id: 'review-1',
                authorId: 'consumer-1',
                targetId: targetId.targetId,
                rating: 4,
                comentario: 'Entrega rápida y buen repuesto.',
                createdAt: DateTime.utc(2026, 8, 20),
                authorName: 'Carlos',
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WriteReviewBottomSheet(
              targetId: 'store-user-1',
              providerName: 'Repuestos Central',
              readOnly: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tu reseña'), findsOneWidget);
    expect(find.text('4 de 5 estrellas'), findsOneWidget);
    expect(find.text('Entrega rápida y buen repuesto.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('GUARDAR CAMBIOS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sheet surface covers the bottom safe area', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 34),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const WriteReviewBottomSheet(
                    targetId: 'store-user-1',
                    providerName: 'Repuestos Central',
                    initialStatus: MyReviewStatus(hasReviewed: false),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    final sheetSurface = find.byKey(
      const Key('write-review-sheet-surface'),
    );
    expect(
      tester.getBottomRight(sheetSurface).dy,
      tester.getBottomRight(find.byType(BottomSheet).last).dy,
    );
    expect(tester.takeException(), isNull);
  });
}
