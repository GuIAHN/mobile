import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/usecases/update_review_usecase.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockReviewsRepository extends Mock implements ReviewsRepository {}

void main() {
  test('keeps the review form in an error state after a duplicate rejection',
      () async {
    final repository = _MockReviewsRepository();
    when(
      () => repository.createReview(
        conversationId: 'conversation-1',
        rating: 4,
        comentario: 'Buen servicio',
      ),
    ).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          message: 'You have already reviewed this provider',
          code: 409,
        ),
      ),
    );
    final notifier = CreateReviewNotifier(
      CreateReviewUseCase(repository),
      UpdateReviewUseCase(repository),
    );

    final saved = await notifier.createReview(
      conversationId: 'conversation-1',
      rating: 4,
      comentario: 'Buen servicio',
    );

    expect(saved, isFalse);
    expect(notifier.state, isA<AsyncError<void>>());
    expect(
      notifier.state.error,
      'You have already reviewed this provider',
    );
  });
}
