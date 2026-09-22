import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';

class HomeRemoteDatasource {
  final DioClient _client;

  HomeRemoteDatasource(this._client);

  Future<Map<String, dynamic>> getTopProviders({
    double? lat,
    double? lng,
  }) async {
    final hasCoordinates = lat != null && lng != null;
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.homeTopProviders,
      queryParameters: {
        if (hasCoordinates) 'lat': lat,
        if (hasCoordinates) 'lng': lng,
      },
    );
    return response.data ?? const {};
  }
}
