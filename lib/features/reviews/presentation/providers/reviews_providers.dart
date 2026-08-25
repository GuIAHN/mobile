import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/reviews_remote_datasource.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import '../../domain/entities/my_review_status.dart';
import '../../domain/entities/pending_review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../../domain/usecases/create_review_usecase.dart';
import '../../domain/usecases/get_reviews_usecase.dart';
import '../../domain/usecases/update_review_usecase.dart';

// ── Dependencies ─────────────────────────────────────────────────────────────

final reviewsRemoteDataSourceProvider =
    Provider<ReviewsRemoteDataSource>((ref) {
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

// ── State Providers ──────────────────────────────────────────────────────────

final reviewsProvider = FutureProvider.family
    .autoDispose<PaginatedReviews, String>((ref, targetId) async {
  final useCase = ref.watch(getReviewsUseCaseProvider);
  final result = await useCase(targetId, page: 1, limit: 20);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (paginated) => paginated,
  );
});

final pendingReviewsProvider =
    FutureProvider.autoDispose<List<PendingReview>>((ref) async {
  final result = await ref.watch(reviewsRepositoryProvider).getPendingReviews();
  final items = result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
  // Keep only successful responses. Transient failures should be retried on
  // the next visit instead of remaining warm for the whole cache window.
  ref.cacheFor(const Duration(minutes: 2));
  return items;
});

final myReviewProvider = FutureProvider.family
    .autoDispose<MyReviewStatus, String>((ref, targetId) async {
  final result =
      await ref.watch(reviewsRepositoryProvider).getMyReview(targetId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (status) => status,
  );
});

final hasContactedProviderProvider = FutureProvider.family
    .autoDispose<bool, String>((ref, providerProfileId) async {
  return ref
      .watch(secureStorageProvider)
      .hasContactedProvider(providerProfileId);
});

final handledStoreReviewProvider = FutureProvider.family
    .autoDispose<bool, String>((ref, conversationId) async {
  return ref.watch(secureStorageProvider).hasHandledStoreReview(conversationId);
});

Future<void> markStoreReviewHandled(
  WidgetRef ref,
  String conversationId,
) async {
  await ref.read(secureStorageProvider).markStoreReviewHandled(conversationId);
  ref.invalidate(handledStoreReviewProvider(conversationId));
}

Future<bool> registerProviderContact(
  WidgetRef ref, {
  required String providerProfileId,
  required String channel,
}) async {
  final result = await ref
      .read(reviewsRepositoryProvider)
      .trackProviderContact(providerProfileId, channel);
  return result.fold<Future<bool>>(
    (_) async => false,
    (_) async {
      await ref
          .read(secureStorageProvider)
          .markProviderContacted(providerProfileId);
      ref.invalidate(hasContactedProviderProvider(providerProfileId));
      return true;
    },
  );
}

// ── Action Providers ─────────────────────────────────────────────────────────

class CreateReviewNotifier extends StateNotifier<AsyncValue<void>> {
  final CreateReviewUseCase _createReviewUseCase;
  final UpdateReviewUseCase _updateReviewUseCase;

  CreateReviewNotifier(this._createReviewUseCase, this._updateReviewUseCase)
      : super(const AsyncValue.data(null));

  Future<bool> createReview({
    String? conversationId,
    String? targetId,
    required int rating,
    String? comentario,
  }) async {
    state = const AsyncValue.loading();
    final result = await _createReviewUseCase(
      conversationId: conversationId,
      targetId: targetId,
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

  Future<bool> updateReview({
    required String reviewId,
    required int rating,
    String? comentario,
  }) async {
    state = const AsyncValue.loading();
    final result = await _updateReviewUseCase(
      reviewId,
      rating: rating,
      comentario: comentario,
    );
    return result.fold(
      (failure) {
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

final createReviewProvider =
    StateNotifierProvider.autoDispose<CreateReviewNotifier, AsyncValue<void>>(
        (ref) {
  return CreateReviewNotifier(
    ref.watch(createReviewUseCaseProvider),
    ref.watch(updateReviewUseCaseProvider),
  );
});
