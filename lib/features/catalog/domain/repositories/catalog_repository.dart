import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category_node.dart';
import '../entities/specialty.dart';

/// Repository contract for fetching global catalogs of specialties and categories.
abstract class CatalogRepository {
  /// Fetches the complete list of mechanic specialties.
  Future<Either<Failure, List<Specialty>>> getSpecialties();

  /// Fetches the full category tree (roots + all nested subcategories).
  /// The tree is cached on the backend (Redis 24h) — one call per session.
  Future<Either<Failure, List<CategoryNode>>> getCategoryTree();
}
