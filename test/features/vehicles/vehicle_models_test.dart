import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/models/car_model_model.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/models/user_car_model.dart';

void main() {
  group('Vehicle Models JSON Parsing', () {
    test(
        'CarModelModel.fromJson should parse model without year/motor and with vehicleType',
        () {
      final json = {
        'id': 'model-1',
        'brandId': 'brand-1',
        'name': 'Corolla',
        'vehicleType': 'CAR',
      };

      final model = CarModelModel.fromJson(json);

      expect(model.id, equals('model-1'));
      expect(model.brandId, equals('brand-1'));
      expect(model.name, equals('Corolla'));
      expect(model.vehicleType, equals('CAR'));
    });

    test(
        'UserCarModel.fromJson parses model, year and motor from the new shape',
        () {
      final json = {
        'id': 'car-1',
        'placa': 'HDN-1234',
        'color': 'Rojo',
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
            'brandType': 'JAPONES',
          },
        },
      };

      final userCar = UserCarModel.fromJson(json);

      expect(userCar.id, equals('car-1'));
      expect(userCar.modelId, equals('model-1'));
      expect(userCar.brand, equals('Toyota'));
      expect(userCar.model, equals('Corolla'));
      expect(userCar.year, equals(2022));
      expect(userCar.motor, equals('1.8L'));
      expect(userCar.placa, equals('HDN-1234'));
      expect(userCar.color, equals('Rojo'));
    });
  });
}
