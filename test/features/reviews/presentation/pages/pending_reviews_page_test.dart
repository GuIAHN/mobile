import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guiautomotriz_mobile/core/router/route_names.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/pending_review.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/pages/pending_reviews_page.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockReviewsRepository extends Mock implements ReviewsRepository {}

Widget _app({
  required Override override,
  Size size = const Size(390, 844),
  double textScale = 1,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [override],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: const PendingReviewsPage(),
      ),
    ),
  );
}

void main() {
  const stalePending = PendingReview(
    targetId: 'mechanic-user-1',
    providerProfileId: 'mechanic-profile-1',
    providerName: 'GoogleMecanico',
  );
  final existingReview = Review(
    id: 'review-1',
    authorId: 'consumer-1',
    targetId: 'mechanic-user-1',
    rating: 3,
    comentario: 'Bueno',
    createdAt: DateTime.utc(2026, 9, 24),
    authorName: 'Pepe',
  );

  testWidgets('edits the saved review when the pending list is stale',
      (tester) async {
    final repository = _MockReviewsRepository();
    when(repository.getPendingReviews)
        .thenAnswer((_) async => const Right([stalePending]));
    when(() => repository.getMyReview('mechanic-user-1')).thenAnswer(
      (_) async => Right(MyReviewStatus(
        hasReviewed: true,
        review: existingReview,
      )),
    );
    when(() => repository.updateReview(
          'review-1',
          rating: 5,
          comentario: 'Bueno',
        )).thenAnswer((_) async => Right(existingReview));
    final router = GoRouter(
      initialLocation: RouteNames.pendingReviews,
      routes: [
        GoRoute(
          path: RouteNames.pendingReviews,
          builder: (_, __) => const PendingReviewsPage(),
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (_, __) => Consumer(builder: (_, ref, __) {
            final count = ref.watch(pendingReviewsProvider).valueOrNull?.length;
            return Scaffold(body: Text('Pendientes: $count'));
          }),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [reviewsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEJAR VALORACIÓN'));
    await tester.pumpAndSettle();

    expect(find.text('Editar valoración'), findsOneWidget);
    expect(find.text('3 de 5 estrellas'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Bueno'), findsOneWidget);
    expect(find.text('PUBLICAR RESEÑA'), findsNothing);

    when(repository.getPendingReviews)
        .thenAnswer((_) async => const Right(<PendingReview>[]));
    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.pump();
    await tester.tap(find.text('GUARDAR CAMBIOS'));
    await tester.pumpAndSettle();

    expect(find.text('Pendientes: 0'), findsOneWidget);
    verify(() => repository.updateReview(
          'review-1',
          rating: 5,
          comentario: 'Bueno',
        )).called(1);
    verifyNever(() => repository.createReview(
          targetId: any(named: 'targetId'),
          rating: any(named: 'rating'),
          comentario: any(named: 'comentario'),
        ));
  });

  testWidgets('refreshes stale reminders when the review sheet is dismissed',
      (tester) async {
    final repository = _MockReviewsRepository();
    when(repository.getPendingReviews)
        .thenAnswer((_) async => const Right([stalePending]));
    when(() => repository.getMyReview('mechanic-user-1')).thenAnswer(
      (_) async => Right(MyReviewStatus(
        hasReviewed: true,
        review: existingReview,
      )),
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [reviewsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: PendingReviewsPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEJAR VALORACIÓN'));
    await tester.pumpAndSettle();
    when(repository.getPendingReviews)
        .thenAnswer((_) async => const Right(<PendingReview>[]));
    Navigator.of(tester.element(find.byType(TextFormField))).pop();
    await tester.pumpAndSettle();

    expect(find.text('Estás al día'), findsOneWidget);
  });

  testWidgets('waits for review status and allows retry before publishing',
      (tester) async {
    final status = Completer<MyReviewStatus>();
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        pendingReviewsProvider.overrideWith((ref) async => [stalePending]),
        myReviewProvider.overrideWith((ref, targetId) {
          attempts++;
          return attempts == 1
              ? status.future
              : Future.value(const MyReviewStatus(hasReviewed: false));
        }),
      ],
      child: const MaterialApp(home: PendingReviewsPage()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DEJAR VALORACIÓN'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('PUBLICAR RESEÑA'), findsNothing);

    status.completeError(Exception('offline'));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tu valoración'), findsOneWidget);
    expect(find.text('PUBLICAR RESEÑA'), findsNothing);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.bySemanticsLabel('5 estrellas'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'PUBLICAR RESEÑA'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('shows delivered stores with a touch-friendly review action',
      (tester) async {
    await tester.pumpWidget(
      _app(
        override: pendingReviewsProvider.overrideWith(
          (ref) async => [
            PendingReview(
              targetId: 'store-user-1',
              providerProfileId: 'store-1',
              providerName: 'Repuestos Centro',
              eligibleAt: DateTime(2026, 8, 20),
              conversationId: 'conversation-1',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Repuestos Centro'), findsOneWidget);
    expect(find.text('DEJAR VALORACIÓN'), findsOneWidget);
    expect(
      tester
          .getSize(find.widgetWithText(ElevatedButton, 'DEJAR VALORACIÓN'))
          .height,
      greaterThanOrEqualTo(48),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the editable review at phone widths with scaled text',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 640), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [
          pendingReviewsProvider.overrideWith((ref) async => [stalePending]),
          myReviewProvider.overrideWith((ref, targetId) async => MyReviewStatus(
                hasReviewed: true,
                review: existingReview,
              )),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 34),
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const PendingReviewsPage(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('DEJAR VALORACIÓN'), 200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('DEJAR VALORACIÓN'));
      await tester.pumpAndSettle();

      expect(find.text('Editar valoración'), findsOneWidget);
      final save = find.widgetWithText(ElevatedButton, 'GUARDAR CAMBIOS');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      expect(
        tester
            .getBottomRight(
              find.byKey(const Key('write-review-sheet-surface')),
            )
            .dy,
        size.height,
      );
      expect(tester.takeException(), isNull, reason: 'phone size $size');
    }
  });

  testWidgets('supports loading, error, and empty states', (tester) async {
    final pendingCompleter = Completer<List<PendingReview>>();
    await tester.pumpWidget(
      _app(
        override: pendingReviewsProvider.overrideWith(
          (ref) => pendingCompleter.future,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNWidgets(3));

    await tester.pumpWidget(
      _app(
        override: pendingReviewsProvider.overrideWith(
          (ref) async => throw Exception('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar tus reseñas'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        override: pendingReviewsProvider.overrideWith((ref) async => []),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Estás al día'), findsOneWidget);
    expect(find.text('IR AL INICIO'), findsOneWidget);
  });

  testWidgets('fits a small phone with enlarged text and reduced motion',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final size in [const Size(320, 640), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _app(
          size: size,
          textScale: 2,
          override: pendingReviewsProvider.overrideWith(
            (ref) async => [
              PendingReview(
                targetId: 'store-user-1',
                providerProfileId: 'store-1',
                providerName: 'Tienda de repuestos con un nombre muy largo',
                eligibleAt: DateTime(2026, 8, 20),
                conversationId: 'conversation-1',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('DEJAR VALORACIÓN'), 200);
      expect(tester.takeException(), isNull, reason: 'phone size $size');
      expect(find.text('DEJAR VALORACIÓN'), findsOneWidget);
    }
  });
}
