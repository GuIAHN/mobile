import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/store_category_config.dart';
import '../models/user_model.dart';

/// Remote data source for authentication.
/// Only interacts with HTTP/Dio and returns Models or throws Exceptions.
class AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSource(this._client);

  /// Calls POST /auth/login and returns the parsed response.
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      if (response.data == null) {
        throw const ParseException();
      }

      return LoginResponseModel.fromJson(response.data!);
    } on ParseException {
      rethrow;
    } catch (e) {
      rethrow; // AuthInterceptor and ErrorMapper will handle the rest.
    }
  }

  /// Calls POST /auth/logout (No-op for the current backend).
  Future<void> logout() async {
    // The current backend does not have a logout endpoint; token expiration is client-side.
  }

  /// Calls POST /auth/register and returns the created user info.
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'userType': role,
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      final data = Map<String, dynamic>.from(response.data!);
      // The backend does not return 'name' in the registration response, so we inject it from the form.
      data['name'] = name;

      return UserModel.fromJson(data);
    } on ParseException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Calls GET /users/me to obtain the current user.
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.me);

    if (response.data == null) {
      throw const ParseException();
    }

    return UserModel.fromJson(response.data!);
  }

  /// Calls PUT /users/me/phone to update the phone number.
  Future<void> updatePhone(String phone) async {
    await _client.put<Map<String, dynamic>>(
      '/users/me/phone',
      data: {'number': phone},
    );
  }

  /// Calls POST /mechanics/register to register a mechanic or workshop.
  Future<UserModel> registerMechanic({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String description,
    required bool isWorkshop,
    required String identification,
    required List<String> specialtyIds,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        'mechanics/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'telefono': phone,
          'ubicacion': {
            'lat': latitude,
            'lon': longitude,
          },
          'descripcion': description,
          'esTaller': isWorkshop,
          'identification': identification,
          'specialtyIds': specialtyIds,
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      final data = Map<String, dynamic>.from(response.data!);
      data['name'] = name;

      return UserModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Calls POST /stores/register to register a spare parts store.
  Future<UserModel> registerStore({
    required String email,
    required String password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required List<StoreCategoryConfig> catalog,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        'stores/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'telefono': phone,
          'ubicacion': {
            'lat': latitude,
            'lon': longitude,
          },
          'direccion': address,
          'rif': rif,
          'categories': catalog.map((c) => {
            'categoryId': c.categoryId,
            'priceDesde': c.minPrice,
            'atiendeTodasMarcas': c.servesAllBrands,
            'brandIds': c.brandIds,
            'sparePartsTypes': c.sparePartsTypes,
          }).toList(),
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      final data = Map<String, dynamic>.from(response.data!);
      data['name'] = name;

      return UserModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Calls POST /stores/me/categories to register a store catalog line.
  Future<void> configureStoreCategory({
    required String categoryId,
    required double minPrice,
    required bool servesAllBrands,
    required List<String> brandIds,
    required List<String> sparePartsTypes,
  }) async {
    try {
      await _client.post<Map<String, dynamic>>(
        'stores/me/categories',
        data: {
          'categoryId': categoryId,
          'priceDesde': minPrice,
          'atiendeTodasMarcas': servesAllBrands,
          'brandIds': brandIds,
          'sparePartsTypes': sparePartsTypes,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

