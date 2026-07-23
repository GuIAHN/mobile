import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/reviews_repository.dart';

class DeleteReviewUseCase {
  final ReviewsRepository repository;

  DeleteReviewUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteReview(id);
  }
}
