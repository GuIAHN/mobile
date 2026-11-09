import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/domain/enums/part_type.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/search_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('publishes quantity and ordered uploaded photos without legacy photoUrl',
      () async {
    final client = _MockDioClient();
    when(() => client.post<Map<String, dynamic>>('/search',
            data: any(named: 'data')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/search'),
            data: {'id': 'r'}));
    await SearchRemoteDatasourceImpl(client).createSearchRequest(
        userCarId: 'car',
        subcategoryId: 'part',
        quantity: 4,
        photoUrls: const ['one', 'two']);
    final payload = verify(() => client.post<Map<String, dynamic>>('/search',
        data: captureAny(named: 'data'))).captured.single as Map;
    expect(payload['quantity'], 4);
    expect(payload['photoUrls'], ['one', 'two']);
    expect(payload.containsKey('photoUrl'), isFalse);
  });

  test('editing sends only description and the complete photo list', () async {
    final client = _MockDioClient();
    when(() => client.patch<Map<String, dynamic>>('/search/r',
            data: any(named: 'data')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/search/r'),
            data: {'id': 'r'}));
    await SearchRemoteDatasourceImpl(client)
        .updateSearchRequest(requestId: 'r', details: '', photoUrls: const []);
    verify(() => client.patch<Map<String, dynamic>>('/search/r',
        data: {'details': '', 'photoUrls': <String>[]})).called(1);
  });

  test('sends USED when creating a used spare-part request', () async {
    final client = _MockDioClient();
    final used = PartType.values.singleWhere(
      (type) => type.apiValue == 'USED',
    );
    when(
      () => client.post<Map<String, dynamic>>(
        '/search',
        data: {
          'quantity': 1,
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
