import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../repositories/provider_profile_repository.dart';

class UpdateProviderSpecialtiesUseCase {
  final ProviderProfileRepository _repository;

  const UpdateProviderSpecialtiesUseCase(this._repository);

  Future<Either<Failure, List<Specialty>>> call(
    List<String> specialtyIds,
  ) {
    return _repository.updateOwnSpecialties(specialtyIds);
  }
}
