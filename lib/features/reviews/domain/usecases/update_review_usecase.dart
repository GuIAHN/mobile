import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class UpdateReviewUseCase {
  final ReviewsRepository repository;

  UpdateReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call(
    String id, {
    int? rating,
    String? comentario,
  }) {
    return repository.updateReview(
      id,
      rating: rating,
      comentario: comentario,
    );
  }
}
