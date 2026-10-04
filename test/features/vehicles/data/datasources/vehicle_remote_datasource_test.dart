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
        data: {'modelId': 'model-1', 'year': 2022, 'motor': '1.8L'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/me/cars'),
        statusCode: 201,
        data: {
          'id': 'car-1',
          'userId': 'user-1',
          'modelId': 'model-1',
          'year': 2022,
          'motor': '1.8L',
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
          'modelId': 'model-1',
          'year': 2022,
          'motor': '1.8L',
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
      ),
    );

    final car = await dataSource.addCarToGarage(
      modelId: 'model-1',
      year: 2022,
      motor: '1.8L',
    );

    expect(car.id, 'car-1');
    expect(car.brand, 'Toyota');
    expect(car.model, 'Corolla');
    expect(car.year, 2022);
    expect(car.brandLogoUrl, 'https://example.com/toyota.png');
  });
}
