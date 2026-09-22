import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/pages/provider_reviews_page.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';

void main() {
  testWidgets('shows the received-reviews empty state for the owner',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewsProvider.overrideWith(
            (ref, targetId) async => const PaginatedReviews(
              items: [],
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProviderReviewsPage(
            targetId: 'store-user-1',
            isOwnProfile: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reseñas recibidas'), findsOneWidget);
    expect(find.text('Aún no has recibido reseñas'), findsOneWidget);
    expect(
      find.text('Cuando un cliente te valore, aparecerá aquí.'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
