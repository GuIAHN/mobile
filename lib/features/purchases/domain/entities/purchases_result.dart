import '../../../../core/domain/entities/paged_result.dart';
import 'consumer_purchase.dart';

class PurchasesResult extends PagedResult<ConsumerPurchase> {
  const PurchasesResult({
    required List<ConsumerPurchase> purchases,
    super.counts,
    super.page,
    super.pageSize,
    super.total,
  }) : super(items: purchases);

  List<ConsumerPurchase> get purchases => items;
}
