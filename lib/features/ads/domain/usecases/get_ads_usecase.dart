import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ad.dart';
import '../repositories/ad_repository.dart';

class GetAdsUseCase {
  final AdRepository repository;

  GetAdsUseCase(this.repository);

  Future<Either<Failure, List<Ad>>> call(double lat, double lng, {int limit = 5}) {
    return repository.getFeed(lat, lng, limit: limit);
  }
}
