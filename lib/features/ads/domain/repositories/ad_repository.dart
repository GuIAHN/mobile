import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ad.dart';

abstract class AdRepository {
  Future<Either<Failure, List<Ad>>> getFeed(double? lat, double? lng, {int limit = 5});
  Future<Either<Failure, void>> trackImpression(String id, double lat, double lng);
  Future<Either<Failure, void>> trackClick(String id, double lat, double lng);
}
