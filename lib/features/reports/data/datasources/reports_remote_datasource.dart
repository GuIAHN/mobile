import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/store_dashboard.dart';
import '../models/store_dashboard_model.dart';

abstract class ReportsRemoteDataSource {
  Future<DashboardResponse> getStoreDashboard({String? from, String? to});

  Future<MetricResult> getStoreMetric(
    String metricId, {
    String? from,
    String? to,
  });

  Future<StoreResponseStatus> getStoreResponseStatus();

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

      return MetricResultModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      _throwIfStoreMetricsBlocked(e);
      throw Exception('Failed to fetch store metric: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch store metric: $e');
    }
  }

  @override
  Future<StoreResponseStatus> getStoreResponseStatus() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      ApiEndpoints.storeResponseStatus,
    );
    return StoreResponseStatusModel.fromJson(response.data ?? const {});
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

      return DashboardResponseModel.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      _throwIfStoreMetricsBlocked(e);
      throw Exception('Failed to fetch dashboard: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }

  void _throwIfStoreMetricsBlocked(DioException exception) {
    if (exception.response?.statusCode != 403) return;

    final body = exception.response?.data;
    if (body is! Map) return;
    final bodyMap = Map<String, dynamic>.from(body);
    final rawData = bodyMap['data'];
    if (rawData is! Map) return;
    final data = Map<String, dynamic>.from(rawData);
    if (data['code'] != 'STORE_METRICS_BLOCKED') return;

    throw StoreMetricsBlockedException(
      message: bodyMap['message'] as String? ??
          'Responde más rápido para recuperar el acceso al dashboard.',
      status: StoreResponseStatusModel.fromJson({
        ...data,
        'blocked': true,
      }),
    );
  }

  Map<String, dynamic> _queryParameters({String? from, String? to}) {
    return {
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
  }
}
