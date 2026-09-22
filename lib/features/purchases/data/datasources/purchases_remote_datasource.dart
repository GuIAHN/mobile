import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/purchases_result.dart';
import '../models/consumer_purchase_model.dart';

class PurchasesRemoteDataSource {
  const PurchasesRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  Future<PurchasesResult> getPurchases({
    String status = 'ALL',
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri(
      path: ApiEndpoints.consumerPurchases,
      queryParameters: {
        'status': status,
        'page': '$page',
        'limit': '$pageSize',
      },
    );
    final response = await _dioClient.get(uri.toString());
    final raw = Map<String, dynamic>.from(response.data as Map);
    final purchases = (raw['items'] as List? ?? const [])
        .map(
          (item) => ConsumerPurchaseModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final counts = (raw['counts'] as Map? ?? const {}).map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
    return PurchasesResult(purchases: purchases, counts: counts);
  }
}
