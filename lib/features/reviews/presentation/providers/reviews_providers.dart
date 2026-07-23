import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/reviews_remote_datasource.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../domain/usecases/create_review_usecase.dart';
import '../../domain/usecases/delete_review_usecase.dart';
import '../../domain/usecases/get_reviews_usecase.dart';
import '../../domain/usecases/update_review_usecase.dart';

// ── Dependencies ─────────────────────────────────────────────────────────────

final reviewsRemoteDataSourceProvider = Provider<ReviewsRemoteDataSource>((ref) {
  return ReviewsRemoteDataSource(ref.watch(dioClientProvider));
});

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepositoryImpl(ref.watch(reviewsRemoteDataSourceProvider));
});

final getReviewsUseCaseProvider = Provider<GetReviewsUseCase>((ref) {
  return GetReviewsUseCase(ref.watch(reviewsRepositoryProvider));
});

final createReviewUseCaseProvider = Provider<CreateReviewUseCase>((ref) {
  return CreateReviewUseCase(ref.watch(reviewsRepositoryProvider));
});

final updateReviewUseCaseProvider = Provider<UpdateReviewUseCase>((ref) {
  return UpdateReviewUseCase(ref.watch(reviewsRepositoryProvider));
});

final deleteReviewUseCaseProvider = Provider<DeleteReviewUseCase>((ref) {
  return DeleteReviewUseCase(ref.watch(reviewsRepositoryProvider));
});

// ── State Providers ──────────────────────────────────────────────────────────

final reviewsProvider = FutureProvider.family.autoDispose<PaginatedReviews, String>((ref, targetId) async {
  final useCase = ref.watch(getReviewsUseCaseProvider);
  final result = await useCase(targetId, page: 1, limit: 20);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (paginated) => paginated,
  );
});

// ── Action Providers ─────────────────────────────────────────────────────────

class CreateReviewNotifier extends StateNotifier<AsyncValue<void>> {
  final CreateReviewUseCase _createReviewUseCase;

  CreateReviewNotifier(this._createReviewUseCase) : super(const AsyncValue.data(null));

  Future<bool> createReview({
    required String conversationId,
    required int rating,
    String? comentario,
  }) async {
    state = const AsyncValue.loading();
    final result = await _createReviewUseCase(
      conversationId: conversationId,
      rating: rating,
      comentario: comentario,
    );

    return result.fold(
      (failure) {
        final lowerMsg = failure.message.toLowerCase();
        if (lowerMsg.contains('already reviewed') ||
            lowerMsg.contains('ya has calificado') ||
            lowerMsg.contains('ya calificaste')) {
          state = const AsyncValue.data(null);
          return true;
        }
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }
}

final createReviewProvider = StateNotifierProvider.autoDispose<CreateReviewNotifier, AsyncValue<void>>((ref) {
  return CreateReviewNotifier(ref.watch(createReviewUseCaseProvider));
});
