import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/brand.dart';
import '../repositories/vehicle_repository.dart';

class GetBrandsUseCase {
  final VehicleRepository repository;

  GetBrandsUseCase(this.repository);

  Future<Either<Failure, List<Brand>>> call() {
    return repository.getBrands();
  }
}
