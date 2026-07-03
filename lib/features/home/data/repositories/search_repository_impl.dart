import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/enums/part_type.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDatasource remoteDataSource;

  SearchRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Map<String, dynamic>>> createSearchRequest({
    required String userCarId,
    required String subcategoryId,
    String? details,
    String? fotoUrl,
    PartType? partType,
    int? radioKm,
    double? lat,
    double? lon,
  }) async {
    try {
      final result = await remoteDataSource.createSearchRequest(
        userCarId: userCarId,
        subcategoryId: subcategoryId,
        details: details,
        fotoUrl: fotoUrl,
        partType: partType,
        radioKm: radioKm,
        lat: lat,
        lon: lon,
      );
      return Right(result);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
