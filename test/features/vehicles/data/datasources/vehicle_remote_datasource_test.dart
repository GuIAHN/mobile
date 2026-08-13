import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/core/network/dio_client.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/datasources/vehicle_remote_datasource.dart';
import 'package:mocktail/mocktail.dart';

class _MockDioClient extends Mock implements DioClient {}

void main() {
  test('hydrates a newly created garage car when POST returns only ids',
      () async {
    final client = _MockDioClient();
    final dataSource = VehicleRemoteDataSource(client);

    when(
      () => client.post<Map<String, dynamic>>(
        '/me/cars',
        data: {'variantId': 'variant-1'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/me/cars'),
        statusCode: 201,
        data: {
          'id': 'car-1',
          'userId': 'user-1',
          'variantId': 'variant-1',
          'placa': null,
          'color': null,
        },
      ),
    );
    when(() => client.get<Map<String, dynamic>>('/me/cars/car-1')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/me/cars/car-1'),
        statusCode: 200,
        data: {
          'id': 'car-1',
          'placa': null,
          'color': null,
          'variant': {
            'id': 'variant-1',
            'year': 2022,
            'model': {
              'id': 'model-1',
              'name': 'Corolla',
              'vehicleType': 'CAR',
              'brand': {
                'id': 'brand-1',
                'name': 'Toyota',
                'photoUrl': 'https://example.com/toyota.png',
              },
            },
          },
        },
      ),
    );

    final car = await dataSource.addCarToGarage(variantId: 'variant-1');

    expect(car.id, 'car-1');
    expect(car.brand, 'Toyota');
    expect(car.model, 'Corolla');
    expect(car.year, 2022);
    expect(car.brandLogoUrl, 'https://example.com/toyota.png');
  });
}
