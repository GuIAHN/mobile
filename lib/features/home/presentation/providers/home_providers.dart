import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/provider_detail.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home_items_usecase.dart';
import '../../domain/usecases/get_promos_usecase.dart';
import '../../domain/usecases/get_provider_detail_usecase.dart';
import '../../domain/usecases/search_providers_usecase.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/domain/entities/user_car.dart';

// ── Datasource & Repositorio ──────────────────────────────────────────────────

final searchRemoteDatasourceProvider = Provider<SearchRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return SearchRemoteDatasourceImpl(client);
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final datasource = ref.watch(searchRemoteDatasourceProvider);
  return HomeRepositoryImpl(datasource);
});

// ── Use Case Providers ────────────────────────────────────────────────────────

final getPromosUseCaseProvider = Provider<GetPromosUseCase>((ref) {
  return GetPromosUseCase(ref.watch(homeRepositoryProvider));
});

final getHomeItemsUseCaseProvider = Provider<GetHomeItemsUseCase>((ref) {
  return GetHomeItemsUseCase(ref.watch(homeRepositoryProvider));
});

final searchProvidersUseCaseProvider = Provider<SearchProvidersUseCase>((ref) {
  return SearchProvidersUseCase(ref.watch(homeRepositoryProvider));
});

final getProviderDetailUseCaseProvider =
    Provider<GetProviderDetailUseCase>((ref) {
  return GetProviderDetailUseCase(ref.watch(homeRepositoryProvider));
});

// ── UI State Providers ────────────────────────────────────────────────────────

/// Categoría seleccionada (Mecánicos, Repuestos, Talleres)
final selectedServiceTypeProvider = StateProvider<ServiceType>((ref) {
  return ServiceType.spareParts;
});

/// Filtros de búsqueda (se envían al backend en mecánicos/talleres)
final homeFiltersProvider = StateProvider<HomeFilters>((ref) {
  return const HomeFilters();
});

/// Indica si la búsqueda por ubicación está activada/compartida
final isLocationSharedProvider = StateProvider<bool>((ref) {
  return false;
});

/// Query de búsqueda textual (filtro local sobre la lista)
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Vehículo seleccionado para buscar mecánicos o talleres
final searchVehicleProvider = StateProvider<UserCar?>((ref) {
  return null;
});

/// Índice de la pestaña activa (0: Home, 1: Chats, 2: Perfil)
final homeTabProvider = StateProvider<int>((ref) {
  return 0;
});

// ── Async Data Providers ──────────────────────────────────────────────────────

/// Promos/banners por tipo de servicio
final promosProvider =
    FutureProvider.family.autoDispose<List<Promo>, ServiceType>(
        (ref, type) async {
  final useCase = ref.watch(getPromosUseCaseProvider);
  final result = await useCase(type);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (promos) => promos,
  );
});

/// Proveedores (mecánicos / talleres) filtrados desde el backend.
/// spareParts usa mock local.
final homeItemsProvider =
    FutureProvider.family.autoDispose<List<HomeItem>, ServiceType>(
        (ref, type) async {
  if (type == ServiceType.spareParts) {
    final useCase = ref.watch(getHomeItemsUseCaseProvider);
    final result = await useCase(type);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (items) => items,
    );
  }

  // Mecánicos y Talleres: usar búsqueda real con filtros actuales
  final filters = ref.watch(homeFiltersProvider);
  final useCase = ref.watch(searchProvidersUseCaseProvider);
  final result = await useCase(type: type, filters: filters);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

/// Perfil completo de un proveedor (mecánico o taller) — para pantalla de detalle.
final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderDetail, ({String id, ServiceType type})>(
        (ref, args) async {
  final useCase = ref.watch(getProviderDetailUseCaseProvider);
  final result = await useCase(id: args.id, type: args.type);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (detail) => detail,
  );
});

/// Lista filtrada localmente (búsqueda textual) sobre los resultados del backend.
final filteredHomeItemsProvider =
    Provider.autoDispose<AsyncValue<List<HomeItem>>>((ref) {
  final selectedType = ref.watch(selectedServiceTypeProvider);
  final itemsAsync = ref.watch(homeItemsProvider(selectedType));
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final filters = ref.watch(homeFiltersProvider);

  return itemsAsync.whenData((items) {
    var list = List<HomeItem>.from(items);

    // 1. Filtro de texto local (sobre el resultado del backend)
    if (query.isNotEmpty) {
      list = list.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.detail.toLowerCase().contains(query) ||
            item.especialidades.any(
                (e) => e.toLowerCase().contains(query));
      }).toList();
    }

    // 2. Solo abiertos (filtro local — backend retorna solo activos)
    if (filters.onlyOpen) {
      list = list.where((item) => item.isOpen).toList();
    }

    // 3. Ordenamiento local (como complemento al orderBy del backend)
    switch (filters.sortBy) {
      case SortOption.cercania:
        list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortOption.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.populares:
        list.sort((a, b) => b.reviews.compareTo(a.reviews));
        break;
    }

    return list;
  });
});

/// Controla si el snack de bienvenida ya fue mostrado en esta sesión.
final welcomeShownProvider = StateProvider<bool>((ref) {
  final isAuthenticated =
      ref.watch(authProvider.select((s) => s.isAuthenticated));
  if (!isAuthenticated) return false;
  return false;
});
