import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/reviews_repository.dart';

class CreateReviewUseCase {
  final ReviewsRepository repository;

  CreateReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call({
    String? conversationId,
    String? targetId,
    required int rating,
    String? comentario,
  }) {
    return repository.createReview(
      conversationId: conversationId,
      targetId: targetId,
      rating: rating,
      comentario: comentario,
    );
  }
}
