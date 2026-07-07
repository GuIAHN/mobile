import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/specialty.dart';
import '../repositories/catalog_repository.dart';

class GetSpecialtiesUseCase {
  final CatalogRepository _repository;

  GetSpecialtiesUseCase(this._repository);

  Future<Either<Failure, List<Specialty>>> call() {
    return _repository.getSpecialties();
  }
}
