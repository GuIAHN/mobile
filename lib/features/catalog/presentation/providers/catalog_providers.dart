import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/repositories/catalog_repository.dart';

/// Provider for the remote catalog datasource.
final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>((ref) {
  final client = ref.watch(dioClientProvider);
  return CatalogRemoteDataSource(client);
});

/// Provider for the catalog repository.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final dataSource = ref.watch(catalogRemoteDataSourceProvider);
  return CatalogRepositoryImpl(dataSource);
});

/// Provider exposing specialties fetched from the backend.
final specialtiesProvider = FutureProvider.autoDispose<List<Specialty>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final result = await repository.getSpecialties();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (specialties) => specialties,
  );
});

/// Provider exposing root categories fetched from the backend.
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final result = await repository.getRootCategories();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

/// Provider exposing subcategories for a specific category id.
final subcategoriesProvider = FutureProvider.family.autoDispose<List<Category>, String>((ref, categoryId) async {
  final repository = ref.watch(catalogRepositoryProvider);
  final result = await repository.getSubcategories(categoryId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (subcategories) => subcategories,
  );
});
