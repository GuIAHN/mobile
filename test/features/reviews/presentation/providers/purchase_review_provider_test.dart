import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/my_review_status.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/review.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:mocktail/mocktail.dart';

class _Repository extends Mock implements ReviewsRepository {}

void main() {
  test(
      'a reviewed purchase does not mark another purchase at the store reviewed',
      () async {
    final repository = _Repository();
    when(() => repository.getMyReview('store-user', offerId: 'offer-1'))
        .thenAnswer((_) async => Right(MyReviewStatus(
            hasReviewed: true,
            review: Review(
              id: 'review-1',
              authorId: 'me',
              targetId: 'store-user',
              offerId: 'offer-1',
              rating: 4,
              createdAt: DateTime.utc(2026, 10, 18),
              authorName: 'Cliente',
            ))));
    when(() => repository.getMyReview('store-user', offerId: 'offer-2'))
        .thenAnswer(
            (_) async => const Right(MyReviewStatus(hasReviewed: false)));
    final container = ProviderContainer(overrides: [
      reviewsRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final first = await container.read(
        myReviewProvider((targetId: 'store-user', offerId: 'offer-1')).future);
    final second = await container.read(
        myReviewProvider((targetId: 'store-user', offerId: 'offer-2')).future);
    expect(first.review?.id, 'review-1');
    expect(second.hasReviewed, isFalse);
    expect(second.review, isNull);
  });

  test('mechanics still query their only review without an offer', () async {
    final repository = _Repository();
    when(() => repository.getMyReview('mechanic-user')).thenAnswer(
        (_) async => const Right(MyReviewStatus(hasReviewed: false)));
    final container = ProviderContainer(overrides: [
      reviewsRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final result = await container.read(
        myReviewProvider((targetId: 'mechanic-user', offerId: null)).future);
    expect(result.hasReviewed, isFalse);
    verify(() => repository.getMyReview('mechanic-user')).called(1);
  });
}
