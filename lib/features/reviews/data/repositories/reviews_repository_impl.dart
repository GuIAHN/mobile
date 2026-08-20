import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/my_review_status.dart';
import '../../domain/entities/pending_review.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_datasource.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;

  ReviewsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedReviews>> getReviewsByTarget(
    String targetId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final paginatedReviews = await remoteDataSource.getReviewsByTarget(
        targetId,
        page: page,
        limit: limit,
      );
      return Right(paginatedReviews);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Review>> createReview({
    String? conversationId,
    String? targetId,
    required int rating,
    String? comentario,
  }) async {
    try {
      final review = await remoteDataSource.createReview(
        conversationId: conversationId,
        targetId: targetId,
        rating: rating,
        comentario: comentario,
      );
      return Right(review);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, Review>> updateReview(
    String id, {
    int? rating,
    String? comentario,
  }) async {
    try {
      final review = await remoteDataSource.updateReview(
        id,
        rating: rating,
        comentario: comentario,
      );
      return Right(review);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String id) async {
    try {
      await remoteDataSource.deleteReview(id);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<PendingReview>>> getPendingReviews() async {
    try {
      return Right(await remoteDataSource.getPendingReviews());
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, MyReviewStatus>> getMyReview(String targetId) async {
    try {
      return Right(await remoteDataSource.getMyReview(targetId));
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> trackProviderContact(
    String providerProfileId,
    String channel,
  ) async {
    try {
      await remoteDataSource.trackProviderContact(providerProfileId, channel);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
