import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promo.dart';
import '../entities/home_item.dart';
import '../entities/service_type.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Promo>>> getPromos(ServiceType type);
  Future<Either<Failure, List<HomeItem>>> getHomeItems(ServiceType type);
}
