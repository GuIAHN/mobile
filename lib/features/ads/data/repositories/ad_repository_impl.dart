import 'package:dartz/dartz.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/ad.dart';
import '../../domain/repositories/ad_repository.dart';
import '../datasources/ad_remote_datasource.dart';

class AdRepositoryImpl implements AdRepository {
  final AdRemoteDataSource remoteDataSource;

  AdRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Ad>>> getFeed(double? lat, double? lng, {int limit = 5}) async {
    try {
      final ads = await remoteDataSource.getFeed(lat, lng, limit: limit);
      return Right(ads);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> trackImpression(String id, double lat, double lng) async {
    try {
      await remoteDataSource.trackImpression(id, lat, lng);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }

  @override
  Future<Either<Failure, void>> trackClick(String id, double lat, double lng) async {
    try {
      await remoteDataSource.trackClick(id, lat, lng);
      return const Right(null);
    } catch (e) {
      return Left(ErrorMapper.map(e));
    }
  }
}
