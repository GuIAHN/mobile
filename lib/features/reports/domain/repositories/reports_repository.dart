import '../entities/store_dashboard.dart';

abstract class ReportsRepository {
  Future<DashboardResponse> getStoreDashboard({String? from, String? to});

  Future<MetricResult> getStoreMetric(
    String metricId, {
    String? from,
    String? to,
  });

  Future<DashboardResponse> getProviderDashboard({String? from, String? to});
}
