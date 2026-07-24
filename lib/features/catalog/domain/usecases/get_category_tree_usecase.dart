import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_node.dart';
import '../repositories/catalog_repository.dart';

/// Use case that fetches the full category tree from the backend.
/// The tree is cached 24h on the server (Redis), so subsequent calls are near-instant.
class GetCategoryTreeUseCase {
  final CatalogRepository _repository;

  GetCategoryTreeUseCase(this._repository);

  Future<Either<Failure, List<CategoryNode>>> call() {
    return _repository.getCategoryTree();
  }
}
