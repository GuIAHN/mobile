import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/car_model.dart';
import '../../domain/entities/user_car.dart';
import '../../domain/entities/vehicle_variant.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_datasource.dart';

/// Concrete implementation of the vehicle repository.
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;

  VehicleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Brand>>> getBrands() async {
    try {
      final brands = await remoteDataSource.getBrands();
      return Right(brands);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<CarModel>>> getBrandModels(String brandId) async {
    try {
      final models = await remoteDataSource.getBrandModels(brandId);
      return Right(models);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<VehicleVariant>>> getModelVariants(String modelId) async {
    try {
      final variants = await remoteDataSource.getModelVariants(modelId);
      return Right(variants);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, UserCar>> addCarToGarage({
    required String variantId,
    String? placa,
    String? color,
  }) async {
    try {
      final car = await remoteDataSource.addCarToGarage(
        variantId: variantId,
        placa: placa,
        color: color,
      );
      return Right(car);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<UserCar>>> getUserCars() async {
    try {
      final cars = await remoteDataSource.getUserCars();
      return Right(cars);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCarFromGarage(String carId) async {
    try {
      await remoteDataSource.deleteCarFromGarage(carId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
