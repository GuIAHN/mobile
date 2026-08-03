import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/vehicle_variant.dart';
import '../repositories/vehicle_repository.dart';

class GetModelVariantsUseCase {
  final VehicleRepository repository;

  GetModelVariantsUseCase(this.repository);

  Future<Either<Failure, List<VehicleVariant>>> call(String modelId) {
    return repository.getModelVariants(modelId);
  }
}
