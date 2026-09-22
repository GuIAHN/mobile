import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/ad_repository.dart';

class TrackAdImpressionUseCase {
  final AdRepository repository;

  TrackAdImpressionUseCase(this.repository);

  Future<Either<Failure, void>> call(String id, double lat, double lng) {
    return repository.trackImpression(id, lat, lng);
  }
}
