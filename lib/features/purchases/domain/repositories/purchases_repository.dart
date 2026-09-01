import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/consumer_purchase.dart';
import '../entities/purchases_result.dart';

abstract class PurchasesRepository {
  Future<Either<Failure, PurchasesResult>> getPurchases({
    PurchaseFilter filter = PurchaseFilter.all,
    int page = 1,
    int pageSize = 20,
  });
}
