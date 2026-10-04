import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/write_review_bottom_sheet.dart';

void main() {
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
                targetId: targetId,
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
