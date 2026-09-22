import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/part_type.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/search_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('sends USED when creating a used spare-part request', () async {
    final client = _MockDioClient();
    final used = PartType.values.singleWhere(
      (type) => type.apiValue == 'USED',
    );
    when(
      () => client.post<Map<String, dynamic>>(
        '/search',
        data: {
          'userCarId': 'car-1',
          'subcategoryId': 'subcategory-1',
          'partType': 'USED',
        },
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/search'),
        data: {'id': 'request-1'},
      ),
    );

    final result = await SearchRemoteDatasourceImpl(client).createSearchRequest(
      userCarId: 'car-1',
      subcategoryId: 'subcategory-1',
      partType: used,
    );

    expect(result['id'], 'request-1');
  });
}
