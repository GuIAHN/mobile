import 'dart:convert';

import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/store_coverage_config.dart';
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

  /// Calls POST /auth/logout to invalidate backend session.
  Future<void> logout() async {
    try {
      await _client.post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (e) {
      rethrow;
    }
  }

  /// Requests a password reset code without revealing whether the account
  /// exists. The backend always returns the same accepted message.
  Future<String> forgotPassword({required String email}) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    final message = response.data?['message'];
    if (message is! String) throw const ParseException();
    return message;
  }

  /// Resets a password using the six-digit code sent by email.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.resetPassword,
      data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      },
    );
    final message = response.data?['message'];
    if (message is! String) throw const ParseException();
    return message;
  }

  /// Calls POST /auth/social/login and returns the parsed response, or throws SocialNotRegisteredException.
  Future<LoginResponseModel> socialLogin({
    required String idToken,
    required String provider,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.socialLogin,
        data: {
          'idToken': idToken,
          'provider': provider,
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      return LoginResponseModel.fromJson(response.data!);
    } on ParseException {
      rethrow;
    } catch (e) {
      if (e is DioException) {
        final res = e.response;
        if (res != null && res.statusCode == 401) {
          final data = res.data;
          if (data is Map<String, dynamic>) {
            final payload = data['data'] ?? data['message'];
            if (payload is Map<String, dynamic> &&
                payload['registered'] == false) {
              throw SocialNotRegisteredException(
                email: payload['email'] as String? ?? '',
                name: payload['name'] as String? ?? '',
                sub: payload['sub'] as String? ?? '',
              );
            }
          }
        }
      }
      rethrow;
    }
  }

  /// Calls POST /auth/register and returns the created user info.
  Future<UserModel> register({
    required String email,
    String? password,
    required String name,
    required String role,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          if (password != null) 'password': password,
          'name': name,
          'userType': role,
          if (idToken != null) 'idToken': idToken,
          if (provider != null) 'provider': provider,
          'acceptedTerms': acceptedTerms,
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

  /// Calls POST /mechanics/register to register a mechanic or workshop.
  Future<UserModel> registerMechanic({
    required String email,
    String? password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String description,
    required bool isWorkshop,
    required String identification,
    required List<String> specialtyIds,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    String? idPhotoPath,
    String? rifPhotoPath,
    String? mercantilRegistryPath,
  }) async {
    try {
      final payload = {
        'email': email,
        if (password != null) 'password': password,
        'name': name,
        'phone': phone,
        'location': {
          'lat': latitude,
          'lon': longitude,
        },
        'description': description,
        'isWorkshop': isWorkshop,
        'identification': identification,
        'specialtyIds': specialtyIds,
        if (idToken != null) 'idToken': idToken,
        if (provider != null) 'provider': provider,
        'acceptedTerms': acceptedTerms,
      };
      final formData = FormData.fromMap({
        'payload': jsonEncode(payload),
        if (idPhotoPath != null)
          'idPhoto': await _registrationDocument(idPhotoPath),
        if (rifPhotoPath != null)
          'rifPhoto': await _registrationDocument(rifPhotoPath),
        if (mercantilRegistryPath != null)
          'mercantilRegistry':
              await _registrationDocument(mercantilRegistryPath),
      });
      final response = await _client.post<Map<String, dynamic>>(
        'mechanics/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
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
    String? password,
    required String name,
    required String phone,
    required double latitude,
    required double longitude,
    required String address,
    required String rif,
    required StoreCoverageConfig coverage,
    required bool hasDelivery,
    String? idToken,
    String? provider,
    required bool acceptedTerms,
    required String rifPhotoPath,
    required String mercantilRegistryPath,
  }) async {
    try {
      final payload = {
        'email': email,
        if (password != null) 'password': password,
        'name': name,
        'phone': phone,
        'location': {'lat': latitude, 'lon': longitude},
        'address': address,
        'rif': rif,
        'coverage': {
          'servesAllBrands': coverage.servesAllBrands,
          if (!coverage.servesAllBrands) 'brandIds': coverage.brandIds,
          'sparePartsTypes': coverage.sparePartsTypes,
          'subcategoryIds': coverage.subcategoryIds,
        },
        'hasDelivery': hasDelivery,
        if (idToken != null) 'idToken': idToken,
        if (provider != null) 'provider': provider,
        'acceptedTerms': acceptedTerms,
      };
      final formData = FormData.fromMap({
        'payload': jsonEncode(payload),
        'rifPhoto': await _registrationDocument(rifPhotoPath),
        'mercantilRegistry': await _registrationDocument(mercantilRegistryPath),
      });
      final response = await _client.post<Map<String, dynamic>>(
        'stores/register',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
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

  Future<MultipartFile> _registrationDocument(String filePath) {
    final filename = filePath.split('/').last.split('\\').last;
    return MultipartFile.fromFile(
      filePath,
      filename: filename.isEmpty ? 'document.jpg' : filename,
    );
  }

  /// Uploads or replaces the current user's profile photo (avatar).
  /// Uses the dedicated `POST users/me/avatar` endpoint that uploads the
  /// file to the bucket and updates the profile in a single step.
  Future<UserModel> uploadAvatar(String filePath) async {
    try {
      final updatedUser = await _client.uploadUserAvatar(filePath);
      return UserModel.fromJson(updatedUser);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the current user's profile details.
  Future<UserModel> updateProfile({
    String? name,
    String? photo,
    String? phone,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {
          if (name != null) 'name': name,
          if (photo != null) 'photo': photo,
          if (phone != null) 'phone': phone,
          if (latitude != null && longitude != null)
            'location': {
              'lat': latitude,
              'lon': longitude,
            },
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      return UserModel.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  /// Calls POST /auth/change-password to update the current user's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Calls POST /users/me/device-tokens to register a device token
  Future<void> registerDeviceToken(String token, {String? deviceOs}) async {
    try {
      await _client.post<Map<String, dynamic>>(
        'users/me/device-tokens',
        data: {
          'token': token,
          if (deviceOs != null) 'deviceOs': deviceOs,
        },
      );
    } catch (e) {
      // It's ok to swallow or just rethrow, mostly it shouldn't crash the app
      rethrow;
    }
  }

  /// Calls POST /users/me/device-tokens/remove to remove a device token
  Future<void> removeDeviceToken(String token) async {
    try {
      await _client.post<Map<String, dynamic>>(
        'users/me/device-tokens/remove',
        data: {
          'token': token,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
