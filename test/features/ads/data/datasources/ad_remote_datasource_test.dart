import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/api_endpoints.dart';
import 'package:guiautomotriz_mobile/features/ads/data/datasources/ad_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  test('maps the ad feed after the response envelope is unwrapped', () async {
    final dio = _MockDio();
    when(
      () => dio.get<dynamic>(
        ApiEndpoints.adsFeed,
        queryParameters: {'limit': 5},
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.adsFeed),
        statusCode: 200,
        data: const [
          {
            'id': '6a89aebc2c0d2be686dcedcd',
            'brandName': 'CVK',
            'type': 'HOME_BANNER',
            'title': 'Descuento en pastillas 24/7',
            'description': 'Llevate 2 pastillas por el precio de UNA !',
            'mediaUrl': 'http://localhost:3000/uploads/ads/banner.jpg',
            'ctaUrl': 'mercadolibre.com',
            'ctaLabel': 'Ver promoción',
          },
        ],
      ),
    );
    final datasource = AdRemoteDataSource(dio);

    final result = await datasource.getFeed(null, null);

    expect(result, hasLength(1));
    expect(result.single.id, '6a89aebc2c0d2be686dcedcd');
    expect(result.single.brandName, 'CVK');
    expect(result.single.type, 'HOME_BANNER');
    expect(
        result.single.mediaUrl, 'http://localhost:3000/uploads/ads/banner.jpg');
    verify(
      () => dio.get<dynamic>(
        ApiEndpoints.adsFeed,
        queryParameters: {'limit': 5},
      ),
    ).called(1);
    verifyNoMoreInteractions(dio);
  });

  test('includes coordinates when requesting a targeted feed', () async {
    final dio = _MockDio();
    when(
      () => dio.get<dynamic>(
        ApiEndpoints.adsFeed,
        queryParameters: {
          'limit': 3,
          'lat': 10.4806,
          'lng': -66.9036,
        },
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: RequestOptions(path: ApiEndpoints.adsFeed),
        statusCode: 200,
        data: const [],
      ),
    );
    final datasource = AdRemoteDataSource(dio);

    final result = await datasource.getFeed(
      10.4806,
      -66.9036,
      limit: 3,
    );

    expect(result, isEmpty);
    verify(
      () => dio.get<dynamic>(
        ApiEndpoints.adsFeed,
        queryParameters: {
          'limit': 3,
          'lat': 10.4806,
          'lng': -66.9036,
        },
      ),
    ).called(1);
    verifyNoMoreInteractions(dio);
  });
}
