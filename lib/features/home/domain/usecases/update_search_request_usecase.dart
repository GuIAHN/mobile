import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_repository.dart';

class UpdateSearchRequestUseCase {
  const UpdateSearchRequestUseCase(this.repository);
  final SearchRepository repository;

  Future<Either<Failure, Map<String, dynamic>>> call(
          {required String requestId,
          required String details,
          required List<String> photoUrls}) =>
      repository.updateSearchRequest(
          requestId: requestId, details: details, photoUrls: photoUrls);
}
