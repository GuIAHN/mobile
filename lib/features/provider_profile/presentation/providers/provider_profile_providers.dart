import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../../data/datasources/provider_profile_remote_datasource.dart';
import '../../data/repositories/provider_profile_repository_impl.dart';
import '../../domain/entities/store_catalog.dart';
import '../../domain/repositories/provider_profile_repository.dart';
import '../../domain/usecases/get_provider_specialties_usecase.dart';
import '../../domain/usecases/get_store_catalog_usecase.dart';
import '../../domain/usecases/update_provider_specialties_usecase.dart';

final providerProfileRemoteDataSourceProvider =
    Provider<ProviderProfileRemoteDataSource>((ref) {
  return ProviderProfileRemoteDataSource(ref.watch(dioClientProvider));
});

final providerProfileRepositoryProvider = Provider<ProviderProfileRepository>(
  (ref) => ProviderProfileRepositoryImpl(
    ref.watch(providerProfileRemoteDataSourceProvider),
  ),
);

final getProviderSpecialtiesUseCaseProvider =
    Provider<GetProviderSpecialtiesUseCase>((ref) {
  return GetProviderSpecialtiesUseCase(
    ref.watch(providerProfileRepositoryProvider),
  );
});

final updateProviderSpecialtiesUseCaseProvider =
    Provider<UpdateProviderSpecialtiesUseCase>((ref) {
  return UpdateProviderSpecialtiesUseCase(
    ref.watch(providerProfileRepositoryProvider),
  );
});

final getStoreCatalogUseCaseProvider = Provider<GetStoreCatalogUseCase>((ref) {
  return GetStoreCatalogUseCase(ref.watch(providerProfileRepositoryProvider));
});

final storeCatalogProvider =
    FutureProvider.autoDispose<StoreCatalog>((ref) async {
  final result = await ref.watch(getStoreCatalogUseCaseProvider)();
  return result.fold(
    (failure) => throw failure,
    (catalog) => catalog,
  );
});

/// Última selección confirmada por el backend durante esta sesión de perfil.
/// Evita un GET adicional después del PATCH, cuya respuesta ya contiene la
/// lista definitiva de especialidades.
final providerSpecialtiesCacheProvider =
    StateProvider.autoDispose<List<Specialty>?>((ref) => null);

final providerSpecialtiesProvider =
    FutureProvider.autoDispose<List<Specialty>>((ref) async {
  final cached = ref.watch(providerSpecialtiesCacheProvider);
  if (cached != null) return cached;

  final result = await ref.watch(getProviderSpecialtiesUseCaseProvider)();
  return result.fold(
    (failure) => throw failure,
    (specialties) => specialties,
  );
});
