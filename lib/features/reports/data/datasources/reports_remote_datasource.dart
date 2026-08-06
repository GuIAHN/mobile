import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/store_dashboard.dart';

abstract class ReportsRemoteDataSource {
  Future<DashboardResponse> getStoreDashboard({String? from, String? to, required bool isProvider});
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final DioClient _dioClient;

  ReportsRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DashboardResponse> getStoreDashboard({String? from, String? to, required bool isProvider}) async {
    final queryParameters = <String, dynamic>{};
    if (from != null) queryParameters['from'] = from;
    if (to != null) queryParameters['to'] = to;

    final endpoint = isProvider ? 'reports/provider/dashboard' : 'reports/store/dashboard';

    try {
      final response = await _dioClient.dio.get(
        endpoint,
        queryParameters: queryParameters,
      );

      return DashboardResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Simplification of error handling for this feature, ideally delegates to a NetworkExceptions handler
      throw Exception('Failed to fetch dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }
}
