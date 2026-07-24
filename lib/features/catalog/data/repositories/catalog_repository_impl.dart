import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_node.dart';
import '../../domain/entities/specialty.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

/// Concrete implementation of the catalog repository.
class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource remoteDataSource;

  CatalogRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Specialty>>> getSpecialties() async {
    try {
      final specialties = await remoteDataSource.getSpecialties();
      return Right(specialties);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getRootCategories() async {
    try {
      final categories = await remoteDataSource.getRootCategories();
      return Right(categories);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getSubcategories(String categoryId) async {
    try {
      final subcategories = await remoteDataSource.getSubcategories(categoryId);
      return Right(subcategories);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, List<CategoryNode>>> getCategoryTree() async {
    try {
      final tree = await remoteDataSource.getCategoryTree();
      return Right(tree);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}

