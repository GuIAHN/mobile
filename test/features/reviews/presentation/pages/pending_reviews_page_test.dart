import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/pending_review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/pages/pending_reviews_page.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';

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
    for (final size in [const Size(320, 640), const Size(430, 932)]) {
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

      expect(tester.takeException(), isNull, reason: 'phone size $size');
      expect(find.text('DEJAR VALORACIÓN'), findsOneWidget);
    }
  });
}
