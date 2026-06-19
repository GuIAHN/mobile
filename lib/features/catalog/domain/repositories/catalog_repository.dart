import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/specialty.dart';

/// Repository contract for fetching global catalogs of specialties and categories.
abstract class CatalogRepository {
  /// Fetches the complete list of mechanic specialties.
  Future<Either<Failure, List<Specialty>>> getSpecialties();

  /// Fetches the list of root spare parts categories.
  Future<Either<Failure, List<Category>>> getRootCategories();
}
