import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/brand_model.dart';
import '../models/car_model_model.dart';
import '../models/user_car_model.dart';
import '../models/vehicle_variant_model.dart';

/// Remote data source to manage vehicle catalog and user's garage.
class VehicleRemoteDataSource {
  final DioClient _client;

  VehicleRemoteDataSource(this._client);

  /// Fetches the list of brands in the catalog.
  Future<List<BrandModel>> getBrands() async {
    try {
      final response = await _client.get<List<dynamic>>('/brands');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the list of models for a specific brand.
  Future<List<CarModelModel>> getBrandModels(String brandId) async {
    try {
      final response = await _client.get<List<dynamic>>('/brands/$brandId/models');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => CarModelModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the list of variants for a specific model.
  Future<List<VehicleVariantModel>> getModelVariants(String modelId) async {
    try {
      final response = await _client.get<List<dynamic>>('/models/$modelId/variants');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => VehicleVariantModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a vehicle to the user's garage using a variantId.
  Future<UserCarModel> addCarToGarage({
    required String variantId,
    String? placa,
    String? color,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/me/cars',
        data: {
          'variantId': variantId,
          if (placa != null && placa.isNotEmpty) 'placa': placa,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );
      if (response.data == null) {
        throw const ParseException();
      }
      final createdCar = UserCarModel.fromJson(response.data!);
      final hasCompleteVehicleIdentity = createdCar.brand.isNotEmpty &&
          createdCar.model.isNotEmpty &&
          createdCar.year > 0;
      if (hasCompleteVehicleIdentity) return createdCar;

      // The create endpoint may return only the new relation ids. Hydrate the
      // authoritative garage record before it reaches the in-memory profile
      // cache, otherwise the UI displays an empty brand/model and year 0.
      final detailResponse = await _client.get<Map<String, dynamic>>(
        '/me/cars/${createdCar.id}',
      );
      if (detailResponse.data == null) {
        throw const ParseException();
      }
      return UserCarModel.fromJson(detailResponse.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all vehicles in the user's garage.
  Future<List<UserCarModel>> getUserCars() async {
    try {
      final response = await _client.get<List<dynamic>>('/me/cars');
      if (response.data == null) {
        throw const ParseException();
      }
      return response.data!
          .map((json) => UserCarModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a car from the user's garage.
  Future<void> deleteCarFromGarage(String carId) async {
    try {
      await _client.delete<void>('/me/cars/$carId');
    } catch (e) {
      rethrow;
    }
  }
}
