import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/home_item.dart';
import '../../domain/entities/promo.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_home_items_usecase.dart';
import '../../domain/usecases/get_promos_usecase.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ── Repositorio e Use Cases Providers ────────────────────────────────────────
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl();
});

final getPromosUseCaseProvider = Provider<GetPromosUseCase>((ref) {
  return GetPromosUseCase(ref.watch(homeRepositoryProvider));
});

final getHomeItemsUseCaseProvider = Provider<GetHomeItemsUseCase>((ref) {
  return GetHomeItemsUseCase(ref.watch(homeRepositoryProvider));
});

// ── UI State Providers ───────────────────────────────────────────────────────

/// Categoría seleccionada (Mecánicos, Repuestos, Talleres)
final selectedServiceTypeProvider = StateProvider<ServiceType>((ref) {
  return ServiceType.spareParts; // Valor por defecto
});

/// Filtros de búsqueda
final homeFiltersProvider = StateProvider<HomeFilters>((ref) {
  return const HomeFilters();
});

/// Query de búsqueda textual
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// Índice de la pestaña activa en la barra de navegación (0: Home, 1: Chats, 2: Perfil)
final homeTabProvider = StateProvider<int>((ref) {
  return 0;
});

// ── Async Data Providers ─────────────────────────────────────────────────────

/// Promociones (banners) para el tipo de servicio seleccionado
final promosProvider = FutureProvider.family.autoDispose<List<Promo>, ServiceType>((ref, type) async {
  final useCase = ref.watch(getPromosUseCaseProvider);
  final result = await useCase(type);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (promos) => promos,
  );
});

/// Todos los ítems para el tipo de servicio seleccionado (sin filtrar)
final homeItemsProvider = FutureProvider.family.autoDispose<List<HomeItem>, ServiceType>((ref, type) async {
  final useCase = ref.watch(getHomeItemsUseCaseProvider);
  final result = await useCase(type);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (items) => items,
  );
});

/// Lista de ítems filtrada, buscada y ordenada de forma reactiva
final filteredHomeItemsProvider = Provider.autoDispose<AsyncValue<List<HomeItem>>>((ref) {
  final selectedType = ref.watch(selectedServiceTypeProvider);
  final itemsAsync = ref.watch(homeItemsProvider(selectedType));
  final filters = ref.watch(homeFiltersProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  return itemsAsync.whenData((items) {
    var list = List<HomeItem>.from(items);

    // 1. Filtrar por búsqueda textual
    if (query.isNotEmpty) {
      list = list.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.detail.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Filtrar por distancia máxima
    list = list.where((item) => item.distanceKm <= filters.maxDistance).toList();

    // 3. Filtrar por valoración mínima
    list = list.where((item) => item.rating >= filters.minRating).toList();

    // 4. Filtrar por disponibilidad (abierto)
    if (filters.onlyOpen) {
      list = list.where((item) => item.isOpen).toList();
    }

    // 5. Ordenamiento
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

/// Tracks whether the welcome toast/snackbar has already been displayed during this session.
final welcomeShownProvider = StateProvider<bool>((ref) {
  final isAuthenticated = ref.watch(authProvider.select((s) => s.isAuthenticated));
  if (!isAuthenticated) {
    return false;
  }
  return false;
});

