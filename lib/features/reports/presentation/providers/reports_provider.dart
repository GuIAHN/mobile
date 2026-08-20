import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/socket_service.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/store_dashboard.dart';
import '../../domain/repositories/reports_repository.dart';

// --- Data Source & Repository Providers ---
final reportsRemoteDataSourceProvider =
    Provider<ReportsRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportsRemoteDataSourceImpl(dioClient);
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final dataSource = ref.watch(reportsRemoteDataSourceProvider);
  return ReportsRepositoryImpl(dataSource);
});

// --- State Providers ---

/// A filter class for the dashboard to allow time selection up to 30 days
class DashboardFilter {
  final DateTime? from;
  final DateTime? to;

  DashboardFilter({this.from, this.to});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardFilter &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => from.hashCode ^ to.hashCode;
}

class DashboardFilterNotifier extends StateNotifier<DashboardFilter> {
  DashboardFilterNotifier()
      : super(
          DashboardFilter(
            from: DateTime.now().subtract(const Duration(days: 30)),
            to: DateTime.now(),
          ),
        );

  void updateDays(int days) {
    state = DashboardFilter(
      from: DateTime.now().subtract(Duration(days: days)),
      to: DateTime.now(),
    );
  }

  int get currentDays {
    if (state.from == null || state.to == null) return 30;
    return state.to!.difference(state.from!).inDays;
  }
}

final dashboardFilterProvider =
    StateNotifierProvider<DashboardFilterNotifier, DashboardFilter>((ref) {
  return DashboardFilterNotifier();
});

/// Alias temporal para los consumidores existentes del dashboard de tienda.
final storeDashboardFilterProvider = dashboardFilterProvider;

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

void _listenForDashboardRefresh(Ref ref) {
  final socketService = ref.watch(socketServiceProvider);
  final notificationSub = socketService.onNotification.listen((event) {
    if (const {
      'search.matched',
      'offer.bought',
      'offer.delivered',
    }.contains(event['tipo'])) {
      ref.invalidateSelf();
    }
  });
  final reconnectSub = socketService.onReconnect.listen((_) {
    ref.invalidateSelf();
  });

  ref.onDispose(() {
    notificationSub.cancel();
    reconnectSub.cancel();
  });
}

final storeDashboardProvider =
    FutureProvider.autoDispose<DashboardResponse>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final user = ref.watch(authProvider).user;
  if (user == null || !user.role.isStore) {
    throw Exception('Dashboard de tienda no autorizado');
  }

  _listenForDashboardRefresh(ref);

  final from = _formatDate(filter.from);
  final to = _formatDate(filter.to);
  final grossSalesFuture = repository
      .getStoreMetric(
        'M-T06',
        from: from,
        to: to,
      )
      .then<MetricResult?>(
        (metric) => metric,
        onError: (Object _, StackTrace __) => null,
      );
  final dashboard = await repository.getStoreDashboard(from: from, to: to);
  final grossSalesMetric = await grossSalesFuture;

  return grossSalesMetric == null
      ? dashboard
      : dashboard.replaceMetric(grossSalesMetric);
});

final providerDashboardProvider =
    FutureProvider.autoDispose<DashboardResponse>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final user = ref.watch(authProvider).user;
  if (user == null || (!user.role.isMechanic && !user.role.isWorkshop)) {
    throw Exception('Dashboard de proveedor no autorizado');
  }

  _listenForDashboardRefresh(ref);

  return repository.getProviderDashboard(
    from: _formatDate(filter.from),
    to: _formatDate(filter.to),
  );
});
