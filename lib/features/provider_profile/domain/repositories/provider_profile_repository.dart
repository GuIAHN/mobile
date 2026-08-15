import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../catalog/domain/entities/specialty.dart';

abstract class ProviderProfileRepository {
  Future<Either<Failure, List<Specialty>>> getOwnSpecialties();

  Future<Either<Failure, List<Specialty>>> updateOwnSpecialties(
    List<String> specialtyIds,
  );
}
