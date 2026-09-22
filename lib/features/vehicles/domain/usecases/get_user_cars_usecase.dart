import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_car.dart';
import '../repositories/vehicle_repository.dart';

class GetUserCarsUseCase {
  final VehicleRepository repository;

  GetUserCarsUseCase(this.repository);

  Future<Either<Failure, List<UserCar>>> call() {
    return repository.getUserCars();
  }
}
