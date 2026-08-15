import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../repositories/provider_profile_repository.dart';

class GetProviderSpecialtiesUseCase {
  final ProviderProfileRepository _repository;

  const GetProviderSpecialtiesUseCase(this._repository);

  Future<Either<Failure, List<Specialty>>> call() {
    return _repository.getOwnSpecialties();
  }
}
