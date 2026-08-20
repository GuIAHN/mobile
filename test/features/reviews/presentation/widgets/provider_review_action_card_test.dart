import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/provider_review_action_card.dart';

void main() {
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
