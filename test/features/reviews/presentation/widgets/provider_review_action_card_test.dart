import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/provider_review_action_card.dart';

void main() {
  testWidgets('purchase context exposes the store review action',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => const MyReviewStatus(hasReviewed: false),
          ),
          hasContactedProviderProvider.overrideWith(
            (ref, providerProfileId) async => false,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProviderReviewActionCard(
              targetId: 'store-user-1',
              providerProfileId: 'store-1',
              providerName: 'Repuestos Centro',
              conversationId: 'conversation-cancelled',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DEJAR VALORACIÓN'), findsOneWidget);
    expect(find.text('Valora tu experiencia'), findsOneWidget);
    await tester.tap(find.text('DEJAR VALORACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cómo fue tu experiencia?'), findsOneWidget);
    expect(
        find.text(
            'Califica a Repuestos Centro. Las estrellas son obligatorias.'),
        findsOneWidget);
  });

  testWidgets('centers the existing provider rating stars', (tester) async {
    final review = Review(
      id: 'review-1',
      authorId: 'consumer-1',
      targetId: 'mechanic-user-1',
      rating: 4,
      createdAt: DateTime(2026),
      authorName: 'Cliente',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myReviewProvider.overrideWith(
            (ref, targetId) async => MyReviewStatus(
              hasReviewed: true,
              review: review,
            ),
          ),
          hasContactedProviderProvider.overrideWith(
            (ref, providerProfileId) async => true,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProviderReviewActionCard(
              targetId: 'mechanic-user-1',
              providerProfileId: 'mechanic-profile-1',
              providerName: 'Mecánico Centro',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stars = find.byKey(const Key('provider-own-review-stars'));
    expect(stars, findsOneWidget);
    expect(tester.getCenter(stars).dx, closeTo(400, 0.1));
  });
}
