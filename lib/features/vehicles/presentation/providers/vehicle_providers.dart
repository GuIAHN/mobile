import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/car_model.dart';
import '../../domain/entities/user_car.dart';
import '../../domain/entities/vehicle_variant.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/usecases/add_car_to_garage_usecase.dart';
import '../../domain/usecases/get_brand_models_usecase.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_model_variants_usecase.dart';
import '../../domain/usecases/get_user_cars_usecase.dart';
import '../../domain/usecases/delete_car_usecase.dart';

/// Remote data source provider.
final vehicleRemoteDataSourceProvider = Provider<VehicleRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return VehicleRemoteDataSource(client);
});

/// Repository provider.
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final dataSource = ref.watch(vehicleRemoteDataSourceProvider);
  return VehicleRepositoryImpl(dataSource);
});

// ── Use Case Providers ───────────────────────────────────────────────────────

final getBrandsUseCaseProvider = Provider<GetBrandsUseCase>((ref) {
  return GetBrandsUseCase(ref.watch(vehicleRepositoryProvider));
});

final getBrandModelsUseCaseProvider = Provider<GetBrandModelsUseCase>((ref) {
  return GetBrandModelsUseCase(ref.watch(vehicleRepositoryProvider));
});

final getModelVariantsUseCaseProvider = Provider<GetModelVariantsUseCase>((ref) {
  return GetModelVariantsUseCase(ref.watch(vehicleRepositoryProvider));
});

final getUserCarsUseCaseProvider = Provider<GetUserCarsUseCase>((ref) {
  return GetUserCarsUseCase(ref.watch(vehicleRepositoryProvider));
});

final addCarToGarageUseCaseProvider = Provider<AddCarToGarageUseCase>((ref) {
  return AddCarToGarageUseCase(ref.watch(vehicleRepositoryProvider));
});

final deleteCarUseCaseProvider = Provider<DeleteCarUseCase>((ref) {
  return DeleteCarUseCase(ref.watch(vehicleRepositoryProvider));
});

// ── Presentation State Providers ─────────────────────────────────────────────

/// Provider for the list of brands.
final brandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) async {
  final useCase = ref.watch(getBrandsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw failure,
    (brands) => brands,
  );
});

/// Provider for specific brand models.
final brandModelsProvider = FutureProvider.family.autoDispose<List<CarModel>, String>((ref, brandId) async {
  final useCase = ref.watch(getBrandModelsUseCaseProvider);
  final result = await useCase(brandId);
  return result.fold(
    (failure) => throw failure,
    (models) => models,
  );
});

/// Provider for specific model variants.
final modelVariantsProvider = FutureProvider.family.autoDispose<List<VehicleVariant>, String>((ref, modelId) async {
  final useCase = ref.watch(getModelVariantsUseCaseProvider);
  final result = await useCase(modelId);
  return result.fold(
    (failure) => throw failure,
    (variants) => variants,
  );
});

/// Provider for the list of cars in the user's garage.
final userCarsProvider = FutureProvider.autoDispose<List<UserCar>>((ref) async {
  final useCase = ref.watch(getUserCarsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw failure,
    (cars) => cars,
  );
});
