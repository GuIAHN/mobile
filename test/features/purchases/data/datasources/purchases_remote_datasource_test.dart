import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/purchases/data/datasources/purchases_remote_datasource.dart';
import 'package:guiautomotriz_mobile/features/purchases/domain/entities/consumer_purchase.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('maps the paginated purchases contract into purchase entities',
      () async {
    final client = _MockDioClient();
    const endpoint = 'me/purchases?status=ALL&page=1&limit=20';
    when(() => client.get(endpoint)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: endpoint),
        statusCode: 200,
        data: const {
          'items': [
            {
              'offerId': 'offer-1',
              'searchRequestId': 'request-1',
              'conversationId': 'conversation-1',
              'status': 'BOUGHT',
              'price': 125,
              'deliveryCost': 25,
              'totalCost': 150,
              'boughtAt': '2026-08-30T12:00:00.000Z',
              'vehicle': {'brand': 'Toyota', 'model': 'Corolla', 'year': 2020},
              'subcategory': {'id': 'subcategory-1', 'name': 'Frenos'},
              'store': {
                'id': 'store-profile-1',
                'name': 'Repuestos Central',
                'reviewTargetId': 'store-user-1',
              },
              'requestPhotoUrl': 'https://images.test/request.jpg',
              'sparePhotoUrl': 'https://images.test/purchased-part.jpg',
              'hasReviewed': false,
              'needsReview': true,
              'canReview': true,
            },
          ],
          'counts': {
            'all': 1,
            'toReceive': 1,
            'delivered': 0,
            'cancelled': 0,
          },
        },
      ),
    );
    final dataSource = PurchasesRemoteDataSource(client);

    final result = await dataSource.getPurchases();

    expect(result.purchases.single.vehicleName, 'Toyota Corolla');
    expect(result.purchases.single.partName, 'Frenos');
    expect(result.purchases.single.status, PurchaseStatus.bought);
    expect(result.purchases.single.offerId, 'offer-1');
    expect(result.purchases.single.totalCost, 150);
    expect(result.purchases.single.photoUrl,
        'https://images.test/purchased-part.jpg');
    expect(result.purchases.single.needsReview, isTrue);
    expect(result.purchases.single.canReview, isTrue);
    expect(result.purchases.single.storeId, 'store-profile-1');
    expect(result.purchases.single.reviewTargetId, 'store-user-1');
    expect(result.counts['toReceive'], 1);
    verify(() => client.get(endpoint)).called(1);
  });
}
