import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/vehicle_repository.dart';

class DeleteCarUseCase {
  final VehicleRepository repository;

  DeleteCarUseCase(this.repository);

  Future<Either<Failure, void>> call(String carId) {
    return repository.deleteCarFromGarage(carId);
  }
}
