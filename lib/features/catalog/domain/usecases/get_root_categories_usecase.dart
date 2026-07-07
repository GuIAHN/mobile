import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../repositories/catalog_repository.dart';

class GetRootCategoriesUseCase {
  final CatalogRepository _repository;

  GetRootCategoriesUseCase(this._repository);

  Future<Either<Failure, List<Category>>> call() {
    return _repository.getRootCategories();
  }
}
