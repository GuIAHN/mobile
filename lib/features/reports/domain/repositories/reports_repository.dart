import '../entities/store_dashboard.dart';

abstract class ReportsRepository {
  Future<DashboardResponse> getStoreDashboard({String? from, String? to});

  Future<StoreResponseStatus> getStoreResponseStatus();

  Future<DashboardResponse> getProviderDashboard({String? from, String? to});
}
