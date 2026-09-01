import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/consumer_purchase.dart';
import '../entities/purchases_result.dart';
import '../repositories/purchases_repository.dart';

class GetConsumerPurchasesUseCase {
  const GetConsumerPurchasesUseCase(this.repository);

  final PurchasesRepository repository;

  Future<Either<Failure, PurchasesResult>> call({
    PurchaseFilter filter = PurchaseFilter.all,
    int page = 1,
    int pageSize = 20,
  }) {
    return repository.getPurchases(
      filter: filter,
      page: page,
      pageSize: pageSize,
    );
  }
}
