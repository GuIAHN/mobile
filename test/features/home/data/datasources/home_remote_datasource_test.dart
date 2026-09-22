import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/home/data/datasources/home_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  late _MockDioClient client;
  late HomeRemoteDatasource datasource;

  setUp(() {
    client = _MockDioClient();
    datasource = HomeRemoteDatasource(client);
  });

  test('fetches both provider groups with one coordinate-aware request',
      () async {
    final payload = <String, dynamic>{
      'workshops': [
        {
          'id': 'workshop-1',
          'name': 'Taller Central',
          'photo': null,
          'isWorkshop': true,
          'description': 'Diagnóstico general',
          'rating': 4.9,
          'ratingCount': 30,
          'verified': true,
          'distanceKm': 2.4,
          'specialties': ['Motor'],
          'source': 'nearby',
        },
      ],
      'mechanics': <Map<String, dynamic>>[],
    };
    when(
      () => client.get<Map<String, dynamic>>(
        'home/top-providers',
        queryParameters: {'lat': 10.4806, 'lng': -66.9036},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'home/top-providers'),
        statusCode: 200,
        data: payload,
      ),
    );

    final result = await datasource.getTopProviders(
      lat: 10.4806,
      lng: -66.9036,
    );

    expect(result, same(payload));
    verify(
      () => client.get<Map<String, dynamic>>(
        'home/top-providers',
        queryParameters: {'lat': 10.4806, 'lng': -66.9036},
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('omits both coordinates when the pair is incomplete', () async {
    when(
      () => client.get<Map<String, dynamic>>(
        'home/top-providers',
        queryParameters: <String, dynamic>{},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: 'home/top-providers'),
        statusCode: 200,
        data: const {'workshops': [], 'mechanics': []},
      ),
    );

    await datasource.getTopProviders(lat: 10.4806);

    verify(
      () => client.get<Map<String, dynamic>>(
        'home/top-providers',
        queryParameters: <String, dynamic>{},
      ),
    ).called(1);
  });
}
