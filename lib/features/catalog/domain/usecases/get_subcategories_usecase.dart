import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../repositories/catalog_repository.dart';

class GetSubcategoriesUseCase {
  final CatalogRepository _repository;

  GetSubcategoriesUseCase(this._repository);

  Future<Either<Failure, List<Category>>> call(String categoryId) {
    return _repository.getSubcategories(categoryId);
  }
}
