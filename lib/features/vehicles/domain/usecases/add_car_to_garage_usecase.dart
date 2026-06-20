import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_car.dart';
import '../repositories/vehicle_repository.dart';

class AddCarToGarageUseCase {
  final VehicleRepository repository;

  AddCarToGarageUseCase(this.repository);

  Future<Either<Failure, UserCar>> call({
    required String modelId,
    String? placa,
    String? color,
  }) {
    return repository.addCarToGarage(
      modelId: modelId,
      placa: placa,
      color: color,
    );
  }
}
