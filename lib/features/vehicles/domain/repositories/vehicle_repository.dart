import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/brand.dart';
import '../entities/car_model.dart';
import '../entities/user_car.dart';
import '../entities/vehicle_variant.dart';

/// Repository contract for brands, models, variants, and vehicle garage.
abstract class VehicleRepository {
  /// Fetches all available vehicle brands.
  Future<Either<Failure, List<Brand>>> getBrands();

  /// Fetches all models for a specific brand.
  Future<Either<Failure, List<CarModel>>> getBrandModels(String brandId);

  /// Fetches all variants for a specific model.
  Future<Either<Failure, List<VehicleVariant>>> getModelVariants(String modelId);

  /// Registers a car in the user's garage using a variantId.
  Future<Either<Failure, UserCar>> addCarToGarage({
    required String variantId,
    String? placa,
    String? color,
  });

  /// Fetches all cars from the user's garage.
  Future<Either<Failure, List<UserCar>>> getUserCars();

  /// Deletes a car from the user's garage.
  Future<Either<Failure, void>> deleteCarFromGarage(String carId);
}
