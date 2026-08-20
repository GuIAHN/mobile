import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/store_dashboard.dart';

abstract class ReportsRemoteDataSource {
  Future<DashboardResponse> getStoreDashboard({String? from, String? to});

  Future<MetricResult> getStoreMetric(
    String metricId, {
    String? from,
    String? to,
  });

  Future<DashboardResponse> getProviderDashboard({String? from, String? to});
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final DioClient _dioClient;

  ReportsRemoteDataSourceImpl(this._dioClient);

  @override
  Future<DashboardResponse> getStoreDashboard({String? from, String? to}) =>
      _getDashboard(ApiEndpoints.storeDashboard, from: from, to: to);

  @override
  Future<MetricResult> getStoreMetric(
    String metricId, {
    String? from,
    String? to,
  }) async {
    final queryParameters = _queryParameters(from: from, to: to);

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        ApiEndpoints.storeMetric(metricId),
        queryParameters: queryParameters,
      );

      return MetricResult.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw Exception('Failed to fetch store metric: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch store metric: $e');
    }
  }

  @override
  Future<DashboardResponse> getProviderDashboard({String? from, String? to}) =>
      _getDashboard(ApiEndpoints.providerDashboard, from: from, to: to);

  Future<DashboardResponse> _getDashboard(
    String endpoint, {
    String? from,
    String? to,
  }) async {
    final queryParameters = _queryParameters(from: from, to: to);

    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParameters,
      );

      return DashboardResponse.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      // Simplification of error handling for this feature, ideally delegates to a NetworkExceptions handler
      throw Exception('Failed to fetch dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }

  Map<String, dynamic> _queryParameters({String? from, String? to}) {
    return {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }
}
