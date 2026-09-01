import 'consumer_purchase.dart';

class PurchasesResult {
  const PurchasesResult({
    required this.purchases,
    this.counts = const {},
  });

  final List<ConsumerPurchase> purchases;
  final Map<String, int> counts;
}
