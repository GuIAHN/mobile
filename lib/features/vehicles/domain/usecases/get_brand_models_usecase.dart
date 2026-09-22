import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/car_model.dart';
import '../repositories/vehicle_repository.dart';

class GetBrandModelsUseCase {
  final VehicleRepository repository;

  GetBrandModelsUseCase(this.repository);

  Future<Either<Failure, List<CarModel>>> call(String brandId) {
    return repository.getBrandModels(brandId);
  }
}
