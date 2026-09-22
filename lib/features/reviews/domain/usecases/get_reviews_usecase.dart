import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/reviews_repository.dart';

class GetReviewsUseCase {
  final ReviewsRepository repository;

  GetReviewsUseCase(this.repository);

  Future<Either<Failure, PaginatedReviews>> call(
    String targetId, {
    int page = 1,
    int limit = 10,
  }) {
    return repository.getReviewsByTarget(
      targetId,
      page: page,
      limit: limit,
    );
  }
}
