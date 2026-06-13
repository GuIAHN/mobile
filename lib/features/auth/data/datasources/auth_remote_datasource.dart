import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Fuente de datos remota para autenticación.
/// Solo conoce HTTP/Dio y devuelve Models o lanza Exceptions.
class AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSource(this._client);

  /// Llama a POST /auth/login y retorna la respuesta parseada.
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
      rethrow; // El AuthInterceptor y ErrorMapper se encargan del resto.
    }
  }

  /// Llama a POST /auth/logout.
  Future<void> logout() async {
    await _client.post<void>(ApiEndpoints.logout);
  }

  /// Llama a POST /auth/register y retorna tokens + usuario.
  Future<LoginResponseModel> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          'fullName': name,
          'role': role,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );

      if (response.data == null) {
        throw const ParseException();
      }

      return LoginResponseModel.fromJson(response.data!);
    } on ParseException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Llama a GET /auth/me para obtener el usuario actual.
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.me);

    if (response.data == null) {
      throw const ParseException();
    }

    return UserModel.fromJson(response.data!);
  }
}
