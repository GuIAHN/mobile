import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_node.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/usecases/get_category_tree_usecase.dart';
import '../../domain/usecases/get_specialties_usecase.dart';
import '../../domain/usecases/get_root_categories_usecase.dart';
import '../../domain/usecases/get_subcategories_usecase.dart';
import '../../domain/usecases/search_categories_usecase.dart';

/// Provider for the remote catalog datasource.
final catalogRemoteDataSourceProvider =
    Provider<CatalogRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return CatalogRemoteDataSource(client);
});

/// Provider for the catalog repository.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dataSource = ref.watch(catalogRemoteDataSourceProvider);
  return CatalogRepositoryImpl(dataSource);
});

/// Provider for the GetSpecialtiesUseCase.
final getSpecialtiesUseCaseProvider = Provider<GetSpecialtiesUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return GetSpecialtiesUseCase(repository);
});

/// Provider for the GetRootCategoriesUseCase.
final getRootCategoriesUseCaseProvider =
    Provider<GetRootCategoriesUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return GetRootCategoriesUseCase(repository);
});

/// Provider for the GetSubcategoriesUseCase.
final getSubcategoriesUseCaseProvider =
    Provider<GetSubcategoriesUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return GetSubcategoriesUseCase(repository);
});

/// Provider for the GetCategoryTreeUseCase.
final getCategoryTreeUseCaseProvider = Provider<GetCategoryTreeUseCase>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return GetCategoryTreeUseCase(repository);
});

/// Provider for the SearchCategoriesUseCase (pure — no repository needed).
final searchCategoriesUseCaseProvider =
    Provider<SearchCategoriesUseCase>((ref) {
  return const SearchCategoriesUseCase();
});

/// Provider exposing specialties fetched from the backend.
final specialtiesProvider =
    FutureProvider.autoDispose<List<Specialty>>((ref) async {
  final useCase = ref.watch(getSpecialtiesUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw failure,
    (specialties) => specialties,
  );
});

/// Provider exposing root categories fetched from the backend.
final categoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
  final useCase = ref.watch(getRootCategoriesUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw failure,
    (categories) => categories,
  );
});

/// Provider exposing subcategories for a specific category id.
final subcategoriesProvider = FutureProvider.family
    .autoDispose<List<Category>, String>((ref, categoryId) async {
  final useCase = ref.watch(getSubcategoriesUseCaseProvider);
  final result = await useCase(categoryId);
  return result.fold(
    (failure) => throw failure,
    (subcategories) => subcategories,
  );
});

/// Provider for the full category tree (roots + all nested subcategories).
///
/// NOT autoDispose — the tree stays alive in memory during the session
/// so every search is local with zero network overhead.
final categoryTreeProvider = FutureProvider<List<CategoryNode>>((ref) async {
  final useCase = ref.watch(getCategoryTreeUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw failure,
    (tree) => tree,
  );
});
