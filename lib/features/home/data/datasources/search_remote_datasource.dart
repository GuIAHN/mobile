import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Contrato del datasource remoto de búsqueda de proveedores.
abstract class SearchRemoteDatasource {
  Future<Map<String, dynamic>> searchMechanics(Map<String, dynamic> params);
  Future<Map<String, dynamic>> searchWorkshops(Map<String, dynamic> params);
  Future<Map<String, dynamic>> getMechanicDetail(String id);
  Future<Map<String, dynamic>> getStoreDetail(String id);
}

/// Implementación HTTP con [DioClient].
/// El [AuthInterceptor] inyecta el Bearer token automáticamente.
class SearchRemoteDatasourceImpl implements SearchRemoteDatasource {
  final DioClient _client;

  SearchRemoteDatasourceImpl(this._client);

  @override
  Future<Map<String, dynamic>> searchMechanics(
      Map<String, dynamic> params) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.searchMechanics,
      queryParameters: params,
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> searchWorkshops(
      Map<String, dynamic> params) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.searchWorkshops,
      queryParameters: params,
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getMechanicDetail(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.mechanicDetail(id),
    );
    return response.data ?? {};
  }

  @override
  Future<Map<String, dynamic>> getStoreDetail(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.storeDetail(id),
    );
    return response.data ?? {};
  }
}
