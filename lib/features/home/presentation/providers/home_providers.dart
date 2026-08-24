import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/provider_detail.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/entities/top_providers_result.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/create_search_request_usecase.dart';
import '../../domain/usecases/get_home_items_usecase.dart';
import '../../domain/usecases/get_promos_usecase.dart';
import '../../domain/usecases/get_provider_detail_usecase.dart';
import '../../domain/usecases/get_top_providers_usecase.dart';
import '../../domain/usecases/search_providers_usecase.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

int _compareKnownDistanceFirst(double? a, double? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

// ── Search Providers ────────────────────────────────────────────────────────
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final dataSource = ref.watch(searchRemoteDatasourceProvider);
  return SearchRepositoryImpl(dataSource);
});

final createSearchRequestUseCaseProvider =
    Provider<CreateSearchRequestUseCase>((ref) {
  final repository = ref.watch(searchRepositoryProvider);
  return CreateSearchRequestUseCase(repository);
});

enum SearchRequestStatus { idle, loading, success, error }

class SearchRequestState {
  final SearchRequestStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const SearchRequestState({
    this.status = SearchRequestStatus.idle,
    this.errorMessage,
    this.data,
  });

  SearchRequestState copyWith({
    SearchRequestStatus? status,
    String? errorMessage,
    Map<String, dynamic>? data,
  }) {
    return SearchRequestState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}

class SearchRequestNotifier extends StateNotifier<SearchRequestState> {
  final CreateSearchRequestUseCase _useCase;
  final Ref? _ref;

  SearchRequestNotifier(this._useCase, [this._ref])
      : super(const SearchRequestState());

  Future<void> submitSearch({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  }) async {
    state = const SearchRequestState(status: SearchRequestStatus.loading);

    final result = await _useCase(
      userCarId: userCarId,
      subcategoryId: subcategoryId,
      details: details,
      fotoUrl: fotoUrl,
      partType: partType,
      radioKm: radioKm,
      lat: lat,
      lon: lon,
    );

    result.fold(
      (failure) {
        state = SearchRequestState(
          status: SearchRequestStatus.error,
          errorMessage: failure.message,
        );
      },
      (data) {
        _ref?.invalidate(consumerRequestsProvider);
        state = SearchRequestState(
          status: SearchRequestStatus.success,
          data: data,
        );
      },
    );
  }

  void reset() {
    state = const SearchRequestState();
  }
}

final searchRequestNotifierProvider =
    StateNotifierProvider<SearchRequestNotifier, SearchRequestState>((ref) {
  final useCase = ref.watch(createSearchRequestUseCaseProvider);
  return SearchRequestNotifier(useCase, ref);
});

// ── Datasource & Repositorio ──────────────────────────────────────────────────

final searchRemoteDatasourceProvider = Provider<SearchRemoteDatasource>((ref) {
  final client = ref.watch(dioClientProvider);
  return SearchRemoteDatasourceImpl(client);
});

final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  return HomeRemoteDatasource(ref.watch(dioClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(
    ref.watch(searchRemoteDatasourceProvider),
    ref.watch(homeRemoteDatasourceProvider),
  );
});

// ── Use Case Providers ────────────────────────────────────────────────────────

final getPromosUseCaseProvider = Provider<GetPromosUseCase>((ref) {
  return GetPromosUseCase(ref.watch(homeRepositoryProvider));
});

final getHomeItemsUseCaseProvider = Provider<GetHomeItemsUseCase>((ref) {
  return GetHomeItemsUseCase(ref.watch(homeRepositoryProvider));
});

final getTopProvidersUseCaseProvider = Provider<GetTopProvidersUseCase>((ref) {
  return GetTopProvidersUseCase(ref.watch(homeRepositoryProvider));
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
  final role = ref.watch(currentRoleProvider);
  if (role.allowedServiceTypes.contains(ServiceType.spareParts)) {
    return ServiceType.spareParts;
  }
  return role.allowedServiceTypes.isNotEmpty
      ? role.allowedServiceTypes.first
      : ServiceType.workshops;
});

/// Filtros de búsqueda (se envían al backend en mecánicos/talleres)
final homeFiltersProvider = StateProvider<HomeFilters>((ref) {
  return const HomeFilters();
});

/// Query de búsqueda textual (filtro local sobre la lista)
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Vehículo seleccionado para buscar mecánicos o talleres
final searchVehicleProvider = StateProvider<UserCar?>((ref) {
  return null;
});

/// ID de variante de vehículo temporario/manual seleccionado
final searchVehicleVariantIdProvider = StateProvider<String?>((ref) {
  return null;
});

@Deprecated('Use searchVehicleVariantIdProvider instead')
final searchVehicleModelIdProvider = searchVehicleVariantIdProvider;

/// Destinos estables de la navegación principal.
///
/// [commerce] se presenta como "Compras" para quien solicita repuestos y
/// como "Ventas" para la tienda. Mantener un valor semántico evita que el
/// índice de Perfil cambie según el rol, como ocurría con los enteros.
enum MainNavigationTab { home, chats, commerce, profile }

final homeTabProvider = StateProvider<MainNavigationTab>((ref) {
  return MainNavigationTab.home;
});

// ── Async Data Providers ──────────────────────────────────────────────────────

/// Promos/banners por tipo de servicio
final promosProvider = FutureProvider.family
    .autoDispose<List<Promo>, ServiceType>((ref, type) async {
  final useCase = ref.watch(getPromosUseCaseProvider);
  final result = await useCase(type);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (promos) => promos,
  );
});

/// Proveedores filtrados desde el backend. Fuera de producción, spareParts
/// conserva el mock local configurado por el repositorio.
final homeItemsProvider = FutureProvider.family
    .autoDispose<List<HomeItem>, ServiceType>((ref, type) async {
  if (type == ServiceType.spareParts) {
    final useCase = ref.watch(getHomeItemsUseCaseProvider);
    final result = await useCase(type);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (items) => items,
    );
  }

  // Mecánicos y Talleres: usar búsqueda real con filtros actuales
  var filters = ref.watch(homeFiltersProvider);
  final role = ref.watch(currentRoleProvider);

  final isLocationShared = ref.watch(isLocationSharedProvider);
  if (role.usesSavedLocationForSearch) {
    // El backend resuelve la ubicación guardada del usuario autenticado
    // cuando lat/lng no vienen en el query.
    filters = filters.copyWith(clearLocation: true);
  } else if (isLocationShared) {
    final locationAsync = ref.watch(userLocationProvider);
    var location = locationAsync.valueOrNull;

    if (location == null && locationAsync.isLoading) {
      // Esperar a que la ubicación termine de cargar para mantener el estado loading del provider
      await ref
          .watch(userLocationProvider.notifier)
          .stream
          .firstWhere((state) => !state.isLoading);
      location = ref.read(userLocationProvider).valueOrNull;
    }

    if (location != null) {
      filters = filters.copyWith(
        lat: location.latitude,
        lon: location.longitude,
      );
    }
  } else {
    filters = filters.copyWith(clearLocation: true);
  }

  final useCase = ref.watch(searchProvidersUseCaseProvider);
  final result = await useCase(type: type, filters: filters);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

/// Una única carga agrupada para las dos secciones destacadas del Home.
final homeTopProvidersProvider =
    FutureProvider.autoDispose<TopProvidersResult>((ref) async {
  ref.cacheFor(const Duration(minutes: 30));
  final role = ref.watch(currentRoleProvider);
  final isLocationShared =
      !role.usesSavedLocationForSearch && ref.watch(isLocationSharedProvider);
  var location =
      isLocationShared ? ref.read(userLocationProvider).valueOrNull : null;

  if (isLocationShared &&
      location == null &&
      ref.read(userLocationProvider).isLoading) {
    await ref
        .read(userLocationProvider.notifier)
        .stream
        .firstWhere((state) => !state.isLoading);
    location = ref.read(userLocationProvider).valueOrNull;
  }

  final result = await ref.watch(getTopProvidersUseCaseProvider)(
    lat: location?.latitude,
    lng: location?.longitude,
  );
  return result.fold(
    (failure) => throw Exception(failure.message),
    (providers) => providers,
  );
});

/// Selector sin I/O: ambas familias observan la misma respuesta agrupada.
final topProvidersProvider = Provider.autoDispose
    .family<AsyncValue<List<HomeItem>>, ServiceType>((ref, type) {
  return ref.watch(homeTopProvidersProvider).whenData((providers) {
    return switch (type) {
      ServiceType.workshops => providers.workshops,
      ServiceType.mechanic => providers.mechanics,
      ServiceType.spareParts || ServiceType.storeDashboard => const [],
    };
  });
});

/// Perfil completo de un proveedor (mecánico o taller) — para pantalla de detalle.
final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderDetail, ({String id, ServiceType type})>((ref, args) async {
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
            item.especialidades.any((e) => e.toLowerCase().contains(query));
      }).toList();
    }

    // 3. Ordenamiento local (como complemento al orderBy del backend)
    switch (filters.sortBy) {
      case SortOption.cercania:
        list.sort(
          (a, b) => _compareKnownDistanceFirst(a.distanceKm, b.distanceKm),
        );
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
