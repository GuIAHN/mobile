import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/places_search_response.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_datasource.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  final PlacesRemoteDataSource _remoteDataSource;

  const PlacesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, PlacesSearchResponse>> search(String query) async {
    try {
      return Right(await _remoteDataSource.search(query));
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }
}
