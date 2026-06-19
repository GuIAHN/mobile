import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/vehicle_remote_datasource.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/car_model.dart';
import '../../domain/entities/user_car.dart';
import '../../domain/repositories/vehicle_repository.dart';

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

/// Provider for the list of brands.
final brandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) async {
  final repository = ref.watch(vehicleRepositoryProvider);
  final result = await repository.getBrands();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (brands) => brands,
  );
});

/// Provider for specific brand models.
final brandModelsProvider = FutureProvider.family.autoDispose<List<CarModel>, String>((ref, brandId) async {
  final repository = ref.watch(vehicleRepositoryProvider);
  final result = await repository.getBrandModels(brandId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (models) => models,
  );
});

/// Provider for the list of cars in the user's garage.
final userCarsProvider = FutureProvider.autoDispose<List<UserCar>>((ref) async {
  final repository = ref.watch(vehicleRepositoryProvider);
  final result = await repository.getUserCars();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (cars) => cars,
  );
});
