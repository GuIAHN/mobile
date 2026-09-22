import '../../domain/entities/store_dashboard.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remoteDataSource;

  ReportsRepositoryImpl(this._remoteDataSource);

  @override
  Future<DashboardResponse> getStoreDashboard({String? from, String? to}) =>
      _remoteDataSource.getStoreDashboard(from: from, to: to);

  @override
  Future<StoreResponseStatus> getStoreResponseStatus() =>
      _remoteDataSource.getStoreResponseStatus();

  @override
  Future<DashboardResponse> getProviderDashboard({String? from, String? to}) =>
      _remoteDataSource.getProviderDashboard(from: from, to: to);
}
