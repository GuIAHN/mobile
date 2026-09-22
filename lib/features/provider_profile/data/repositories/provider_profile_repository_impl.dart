import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/specialty.dart';
import '../../domain/entities/store_catalog.dart';
import '../../domain/repositories/provider_profile_repository.dart';
import '../datasources/provider_profile_remote_datasource.dart';

class ProviderProfileRepositoryImpl implements ProviderProfileRepository {
  final ProviderProfileRemoteDataSource _remoteDataSource;

  const ProviderProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Specialty>>> getOwnSpecialties() async {
    try {
      return Right(await _remoteDataSource.getOwnSpecialties());
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, List<Specialty>>> updateOwnSpecialties(
    List<String> specialtyIds,
  ) async {
    try {
      return Right(
        await _remoteDataSource.updateOwnSpecialties(specialtyIds),
      );
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, StoreCatalog>> getOwnCatalog() async {
    try {
      return Right(await _remoteDataSource.getOwnCatalog());
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }
}
