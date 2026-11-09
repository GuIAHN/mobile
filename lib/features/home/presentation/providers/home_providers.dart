import '../../domain/usecases/update_search_request_usecase.dart';
import '../../../../core/error/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/cache_for.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/session/session_generation_provider.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/provider_search_page.dart';
import '../../domain/entities/provider_detail.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/entities/top_providers_result.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/create_search_request_usecase.dart';
import '../../domain/usecases/get_home_items_usecase.dart';
import '../../domain/usecases/get_provider_detail_usecase.dart';
import '../../domain/usecases/get_top_providers_usecase.dart';
import '../../domain/usecases/search_providers_usecase.dart';
import '../../../../core/domain/entities/user_car.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

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

final updateSearchRequestUseCaseProvider = Provider<UpdateSearchRequestUseCase>(
    (ref) => UpdateSearchRequestUseCase(ref.watch(searchRepositoryProvider)));

enum SearchRequestStatus { idle, loading, success, error }

class SearchRequestState {
  final SearchRequestStatus status;
  final String? errorMessage;
  final Failure? failure;

  const SearchRequestState({
    this.status = SearchRequestStatus.idle,
    this.errorMessage,
    this.failure,
  });
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
    int quantity = 1,
    List<String>? photoUrls,
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
      quantity: quantity,
      photoUrls: photoUrls,
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
          failure: failure,
        );
      },
      (_) {
        _ref?.invalidate(consumerRequestsProvider);
        state = const SearchRequestState(status: SearchRequestStatus.success);
      },
    );
  }

  void reset() {
    state = const SearchRequestState();
  }
}

final searchRequestNotifierProvider =
    StateNotifierProvider<SearchRequestNotifier, SearchRequestState>((ref) {
  ref.watch(sessionGenerationProvider);
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
  ref.watch(sessionGenerationProvider);
  return const HomeFilters();
});

/// Query de búsqueda textual (filtro local sobre la lista)
final searchQueryProvider = StateProvider<String>((ref) {
  ref.watch(sessionGenerationProvider);
  return '';
});

/// Vehículo seleccionado para buscar mecánicos o talleres
final searchVehicleProvider = StateProvider<UserCar?>((ref) {
  ref.watch(sessionGenerationProvider);
  return null;
});

/// ID de modelo del vehículo temporario/manual seleccionado.
final searchVehicleModelIdProvider = StateProvider<String?>((ref) {
  ref.watch(sessionGenerationProvider);
  return null;
});

/// Destinos estables de la navegación principal.
///
enum MainNavigationTab { home, purchases, requests, profile }

final homeTabProvider = StateProvider<MainNavigationTab>((ref) {
  ref.watch(sessionGenerationProvider);
  return MainNavigationTab.home;
});

// ── Async Data Providers ──────────────────────────────────────────────────────

/// Proveedores filtrados desde el backend. Fuera de producción, spareParts
/// conserva el mock local configurado por el repositorio.
final homeItemsProvider = FutureProvider.family
    .autoDispose<List<HomeItem>, ServiceType>((ref, type) async {
  ref.watch(sessionGenerationProvider);
  if (type == ServiceType.spareParts) {
    final useCase = ref.watch(getHomeItemsUseCaseProvider);
    final result = await useCase(type);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (items) => items,
    );
  }

  final useCase = ref.watch(searchProvidersUseCaseProvider);
  final filters = await ref.watch(providerSearchFiltersProvider.future);
  final result = await useCase(type: type, filters: filters);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

/// Resolve the same location policy for every page of a directory search.
final providerSearchFiltersProvider =
    FutureProvider.autoDispose<HomeFilters>((ref) async {
  ref.watch(sessionGenerationProvider);
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

  return filters;
});

/// Una única carga agrupada para las dos secciones destacadas del Home.
final homeTopProvidersProvider =
    FutureProvider.autoDispose<TopProvidersResult>((ref) async {
  ref.watch(sessionGenerationProvider);
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
  return ref
      .watch(filteredProvidersProvider(ref.watch(selectedServiceTypeProvider)));
});

final filteredProvidersProvider = Provider.autoDispose
    .family<AsyncValue<List<HomeItem>>, ServiceType>((ref, selectedType) {
  final itemsAsync = ref
      .watch(paginatedProvidersProvider(selectedType))
      .whenData((state) => state.items);
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

    // Rating and distance already come ordered by the server. Re-sorting
    // accumulated pages can move unseen providers above the scroll position.
    // Popularity is only exposed after the complete directory has loaded.
    if (filters.sortBy == SortOption.populares) {
      list.sort((a, b) => b.reviews.compareTo(a.reviews));
    }

    return list;
  });
});

class ProvidersListState {
  final List<HomeItem> items;
  final int? total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  const ProvidersListState({
    required this.items,
    this.total,
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  factory ProvidersListState.fromPage(ProviderSearchPage page) =>
      ProvidersListState(
        items: List.unmodifiable(page.items),
        total: page.total,
        page: page.page,
        hasMore: page.hasMore,
      );
}

final paginatedProvidersProvider = AsyncNotifierProvider.autoDispose
    .family<PaginatedProvidersNotifier, ProvidersListState, ServiceType>(
  PaginatedProvidersNotifier.new,
);

class PaginatedProvidersNotifier
    extends AutoDisposeFamilyAsyncNotifier<ProvidersListState, ServiceType> {
  int _generation = 0;
  late HomeRepository _repository;
  late HomeFilters _filters;

  @override
  Future<ProvidersListState> build(ServiceType arg) async {
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    ref.watch(sessionGenerationProvider);
    final repository = ref.watch(homeRepositoryProvider);
    final filters = await ref.watch(providerSearchFiltersProvider.future);
    if (generation != _generation) throw StateError('Search superseded');
    _repository = repository;
    _filters = filters;
    final result =
        await repository.searchProvidersPage(type: arg, filters: filters);
    var page = result.fold(
        (failure) => throw Exception(failure.message), (page) => page);
    if (filters.sortBy != SortOption.populares) {
      return ProvidersListState.fromPage(page);
    }

    // This API cannot order by popularity. Load the entire matching set before
    // showing that local order, so later pages never insert above the viewport.
    final items = [...page.items];
    final ids = items.map((item) => item.id).whereType<String>().toSet();
    while (page.hasMore) {
      if (generation != _generation) throw StateError('Search superseded');
      final next = await repository.searchProvidersPage(
        type: arg,
        filters: filters,
        page: page.page + 1,
      );
      if (generation != _generation) throw StateError('Search superseded');
      final nextPage = next.fold(
          (failure) => throw Exception(failure.message), (page) => page);
      if (nextPage.page <= page.page) break;
      items.addAll(
          nextPage.items.where((item) => item.id == null || ids.add(item.id!)));
      page = nextPage;
    }
    return ProvidersListState(
        items: List.unmodifiable(items), total: page.total, page: page.page);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (state.isLoading ||
        current == null ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    final generation = _generation;
    state = AsyncData(ProvidersListState(
      items: current.items,
      total: current.total,
      page: current.page,
      hasMore: current.hasMore,
      isLoadingMore: true,
    ));
    try {
      final result = await _repository.searchProvidersPage(
        type: arg,
        filters: _filters,
        page: current.page + 1,
      );
      if (generation != _generation) return;
      state = result.fold(
        (failure) => AsyncData(ProvidersListState(
          items: current.items,
          total: current.total,
          page: current.page,
          hasMore: current.hasMore,
          loadMoreError: failure.message,
        )),
        (page) {
          final ids =
              current.items.map((item) => item.id).whereType<String>().toSet();
          final added =
              page.items.where((item) => item.id == null || ids.add(item.id!));
          return AsyncData(ProvidersListState(
            items: List.unmodifiable([...current.items, ...added]),
            total: page.total,
            page: page.page,
            hasMore: page.hasMore && page.page > current.page,
          ));
        },
      );
    } catch (error) {
      if (generation != _generation) return;
      state = AsyncData(ProvidersListState(
        items: current.items,
        total: current.total,
        page: current.page,
        hasMore: current.hasMore,
        loadMoreError: error.toString(),
      ));
    }
  }
}
