import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../entities/my_review_status.dart';
import '../entities/pending_review.dart';

class PaginatedReviews {
  final List<Review> items;

  const PaginatedReviews({
    required this.items,
  });
}

abstract class ReviewsRepository {
  Future<Either<Failure, PaginatedReviews>> getReviewsByTarget(
    String targetId, {
    int page = 1,
    int limit = 10,
  });

  Future<Either<Failure, Review>> createReview({
    String? offerId,
    String? targetId,
    required int rating,
    String? comentario,
  });

  Future<Either<Failure, Review>> updateReview(
    String id, {
    int? rating,
    String? comentario,
  });

  Future<Either<Failure, List<PendingReview>>> getPendingReviews();

  Future<Either<Failure, MyReviewStatus>> getMyReview(String targetId,
      {String? offerId});

  Future<Either<Failure, void>> dismissPendingReview(String promptId);

  Future<Either<Failure, void>> trackProviderContact(
    String providerProfileId,
    String channel,
  );
}
