import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_car.dart';
import '../repositories/vehicle_repository.dart';

class AddCarToGarageUseCase {
  final VehicleRepository repository;

  AddCarToGarageUseCase(this.repository);

  Future<Either<Failure, UserCar>> call({
    required String modelId,
    required int year,
    String? motor,
    String? placa,
    String? color,
  }) {
    return repository.addCarToGarage(
      modelId: modelId,
      year: year,
      motor: motor,
      placa: placa,
      color: color,
    );
  }
}
