import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/ad_repository.dart';

class TrackAdClickUseCase {
  final AdRepository repository;

  TrackAdClickUseCase(this.repository);

  Future<Either<Failure, void>> call(String id, double lat, double lng) {
    return repository.trackClick(id, lat, lng);
  }
}
