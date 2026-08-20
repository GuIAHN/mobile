import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../entities/my_review_status.dart';
import '../entities/pending_review.dart';

class PaginatedReviews {
  final List<Review> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedReviews({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });
}

abstract class ReviewsRepository {
  Future<Either<Failure, PaginatedReviews>> getReviewsByTarget(
    String targetId, {
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, Review>> createReview({
    String? conversationId,
    String? targetId,
    required int rating,
    String? comentario,
  });

  Future<Either<Failure, Review>> updateReview(
    String id, {
    int? rating,
    String? comentario,
  });

  Future<Either<Failure, void>> deleteReview(String id);

  Future<Either<Failure, List<PendingReview>>> getPendingReviews();

  Future<Either<Failure, MyReviewStatus>> getMyReview(String targetId);

  Future<Either<Failure, void>> trackProviderContact(
    String providerProfileId,
    String channel,
  );
}
