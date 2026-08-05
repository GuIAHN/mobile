import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_car.dart';
import '../repositories/vehicle_repository.dart';

class AddCarToGarageUseCase {
  final VehicleRepository repository;

  AddCarToGarageUseCase(this.repository);

  Future<Either<Failure, UserCar>> call({
    required String variantId,
    String? placa,
    String? color,
  }) {
    return repository.addCarToGarage(
      variantId: variantId,
      placa: placa,
      color: color,
    );
  }
}
