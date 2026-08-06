import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/socket_service.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/entities/store_dashboard.dart';
import '../../domain/repositories/reports_repository.dart';

// --- Data Source & Repository Providers ---
final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
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
  DashboardFilterNotifier() : super(
    DashboardFilter(
      from: DateTime.now().subtract(const Duration(days: 30)),
      to: DateTime.now(),
    )
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

final storeDashboardFilterProvider = StateNotifierProvider<DashboardFilterNotifier, DashboardFilter>((ref) {
  return DashboardFilterNotifier();
});



final storeDashboardProvider = FutureProvider.autoDispose<DashboardResponse>((ref) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final filter = ref.watch(storeDashboardFilterProvider);
  final user = ref.watch(authProvider).user;
  
  if (user == null) throw Exception('Usuario no autenticado');

  final isProvider = user.role.isMechanic || user.role.isWorkshop;

  // Listen to real-time events to update the dashboard automatically
  final socketService = ref.watch(socketServiceProvider);
  
  final offerSub = socketService.onOfferUpdated.listen((_) {
    ref.invalidateSelf();
  });
  
  final searchSub = socketService.onSearchMatched.listen((_) {
    ref.invalidateSelf();
  });
  
  ref.onDispose(() {
    offerSub.cancel();
    searchSub.cancel();
  });

  return repository.getStoreDashboard(
    from: filter.from != null ? "${filter.from!.year.toString().padLeft(4, '0')}-${filter.from!.month.toString().padLeft(2, '0')}-${filter.from!.day.toString().padLeft(2, '0')}" : null,
    to: filter.to != null ? "${filter.to!.year.toString().padLeft(4, '0')}-${filter.to!.month.toString().padLeft(2, '0')}-${filter.to!.day.toString().padLeft(2, '0')}" : null,
    isProvider: isProvider,
  );
});
