import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/domain/enums/part_type.dart';

/// Contrato del datasource remoto de búsqueda de proveedores y creación de búsquedas de repuestos.
abstract class SearchRemoteDatasource {
  Future<Map<String, dynamic>> searchMechanics(Map<String, dynamic> params);
  Future<Map<String, dynamic>> searchWorkshops(Map<String, dynamic> params);
  Future<Map<String, dynamic>> getMechanicDetail(String id);
  Future<Map<String, dynamic>> getStoreDetail(String id);

  /// Envía la solicitud de búsqueda de repuesto al backend.
  Future<Map<String, dynamic>> createSearchRequest({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  });
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

  @override
  Future<Map<String, dynamic>> createSearchRequest({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  }) async {
    try {
      final payload = {
        'userCarId': userCarId,
        'subcategoryId': subcategoryId,
        if (details != null && details.isNotEmpty) 'details': details,
        if (fotoUrl != null && fotoUrl.isNotEmpty) 'photoUrl': fotoUrl,
        if (partType != null) 'partType': partType.apiValue,
        if (radioKm != null) 'radiusKm': radioKm,
        if (lat != null) 'lat': lat,
        if (lon != null) 'lon': lon,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/search',
        data: payload,
      );

      if (response.data == null) {
        throw const ParseException();
      }

      return response.data!;
    } catch (e) {
      rethrow;
    }
  }
}
