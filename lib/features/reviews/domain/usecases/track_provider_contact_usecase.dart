import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/reviews_repository.dart';

class TrackProviderContactUseCase {
  final ReviewsRepository repository;

  TrackProviderContactUseCase(this.repository);

  Future<Either<Failure, void>> call(String profileId, String channel) =>
      repository.trackProviderContact(profileId, channel);
}
