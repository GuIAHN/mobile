import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/widgets/review_card.dart';

void main() {
  final review = Review(
    id: 'review-1',
    authorId: 'consumer-1',
    targetId: 'provider-1',
    rating: 5,
    comentario: 'Excelente atención y muy buen servicio.',
    createdAt: DateTime(2026, 8, 20),
    authorName: 'Cliente con un nombre bastante largo',
  );

  for (final width in [320.0, 430.0]) {
    testWidgets('fits the review card at ${width.toInt()} dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 700),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ReviewCard(review: review),
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('5 de 5 estrellas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
