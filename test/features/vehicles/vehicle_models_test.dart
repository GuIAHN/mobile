import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/models/car_model_model.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/models/vehicle_variant_model.dart';
import 'package:guiautomotriz_mobile/features/vehicles/data/models/user_car_model.dart';

void main() {
  group('Vehicle Models JSON Parsing', () {
    test('CarModelModel.fromJson should parse model without year/motor and with vehicleType', () {
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

    test('VehicleVariantModel.fromJson should parse variant with year and motor', () {
      final json = {
        'id': 'variant-1',
        'modelId': 'model-1',
        'year': 2022,
        'motor': 'I4 1.8L Dual VVT-i',
      };

      final variant = VehicleVariantModel.fromJson(json);

      expect(variant.id, equals('variant-1'));
      expect(variant.modelId, equals('model-1'));
      expect(variant.year, equals(2022));
      expect(variant.motor, equals('I4 1.8L Dual VVT-i'));
    });

    test('UserCarModel.fromJson should parse 3-table nested structure (variant -> model -> brand)', () {
      final json = {
        'id': 'car-1',
        'placa': 'HDN-1234',
        'color': 'Rojo',
        'variant': {
          'id': 'variant-1',
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
        },
      };

      final userCar = UserCarModel.fromJson(json);

      expect(userCar.id, equals('car-1'));
      expect(userCar.brand, equals('Toyota'));
      expect(userCar.model, equals('Corolla'));
      expect(userCar.year, equals(2022));
      expect(userCar.placa, equals('HDN-1234'));
      expect(userCar.color, equals('Rojo'));
    });
  });
}
