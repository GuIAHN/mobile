import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/brand_model.dart';
import '../models/car_model_model.dart';
import '../models/user_car_model.dart';

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

  /// Adds a vehicle to the user's garage.
  Future<UserCarModel> addCarToGarage({
    required String modelId,
    String? placa,
    String? color,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/me/cars',
        data: {
          'modelId': modelId,
          if (placa != null && placa.isNotEmpty) 'placa': placa,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );
      if (response.data == null) {
        throw const ParseException();
      }
      return UserCarModel.fromJson(response.data!);
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
}
