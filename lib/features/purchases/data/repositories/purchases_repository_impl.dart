import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/consumer_purchase.dart';
import '../../domain/entities/purchases_result.dart';
import '../../domain/repositories/purchases_repository.dart';
import '../datasources/purchases_remote_datasource.dart';

class PurchasesRepositoryImpl implements PurchasesRepository {
  const PurchasesRepositoryImpl(this.remoteDataSource);

  final PurchasesRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, PurchasesResult>> getPurchases({
    PurchaseFilter filter = PurchaseFilter.all,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      return Right(
        await remoteDataSource.getPurchases(
          status: _filterToApi(filter),
          page: page,
          pageSize: pageSize,
        ),
      );
    } catch (error) {
      return Left(ErrorMapper.map(error));
    }
  }
}

String _filterToApi(PurchaseFilter filter) => switch (filter) {
      PurchaseFilter.all => 'ALL',
      PurchaseFilter.toReceive => 'TO_RECEIVE',
      PurchaseFilter.delivered => 'DELIVERED',
      PurchaseFilter.cancelled => 'CANCELLED',
    };
