import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/promo.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../repositories/home_repository.dart';

class GetPromosUseCase {
  final HomeRepository repository;

  GetPromosUseCase(this.repository);

  Future<Either<Failure, List<Promo>>> call(ServiceType type) {
    return repository.getPromos(type);
  }
}
