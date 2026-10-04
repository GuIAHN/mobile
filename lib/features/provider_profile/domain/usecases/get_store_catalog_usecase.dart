import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/store_catalog.dart';
import '../repositories/provider_profile_repository.dart';

class GetStoreCatalogUseCase {
  final ProviderProfileRepository _repository;

  const GetStoreCatalogUseCase(this._repository);

  Future<Either<Failure, StoreCatalog>> call() {
    return _repository.getOwnCatalog();
  }
}
