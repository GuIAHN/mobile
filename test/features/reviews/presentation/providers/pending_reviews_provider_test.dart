import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/error/failures.dart';
import 'package:guiautomotriz_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:guiautomotriz_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/entities/pending_review.dart';
import 'package:guiautomotriz_mobile/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:guiautomotriz_mobile/features/reviews/presentation/providers/reviews_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockReviewsRepository extends Mock implements ReviewsRepository {}

class _MockChatRepository extends Mock implements ChatRepository {}

void main() {
  test('loads pending reviews with one API path and never hydrates chats',
      () async {
    final reviewsRepository = _MockReviewsRepository();
    final chatRepository = _MockChatRepository();
    const pending = PendingReview(
      targetId: 'store-user-1',
      providerProfileId: 'store-1',
      providerName: 'Repuestos Centro',
      conversationId: 'conversation-1',
    );
    when(reviewsRepository.getPendingReviews).thenAnswer(
      (_) async => const Right([pending]),
    );

    final container = ProviderContainer(
      overrides: [
        reviewsRepositoryProvider.overrideWithValue(reviewsRepository),
        chatRepositoryProvider.overrideWithValue(chatRepository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(pendingReviewsProvider.future);

    expect(result, const [pending]);
    verify(reviewsRepository.getPendingReviews).called(1);
    verifyNever(chatRepository.getMyConversations);
    verifyNever(() => chatRepository.getConversationDetails(any()));
  });

  test('does not retain a transient pending-review failure', () async {
    final reviewsRepository = _MockReviewsRepository();
    var requestCount = 0;
    when(reviewsRepository.getPendingReviews).thenAnswer((_) async {
      requestCount++;
      if (requestCount == 1) {
        return const Left(ServerFailure(message: 'offline'));
      }
      return const Right(<PendingReview>[]);
    });
    final container = ProviderContainer(
      overrides: [
        reviewsRepositoryProvider.overrideWithValue(reviewsRepository),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      pendingReviewsProvider,
      (_, __) {},
      fireImmediately: true,
    );
    await expectLater(
      container.read(pendingReviewsProvider.future),
      throwsException,
    );
    subscription.close();
    await Future<void>.delayed(Duration.zero);

    expect(
      await container.read(pendingReviewsProvider.future),
      const <PendingReview>[],
    );
    verify(reviewsRepository.getPendingReviews).called(2);
  });
}
