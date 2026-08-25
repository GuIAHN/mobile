import '../../domain/entities/car_model.dart';

/// Vehicle model data model with JSON support.
class CarModelModel extends CarModel {
  const CarModelModel({
    required super.id,
    required super.brandId,
    required super.name,
    required super.vehicleType,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String? ?? json['brand_id'] as String? ?? '',
      name: json['name'] as String,
      vehicleType: json['vehicleType'] as String? ??
          json['vehicle_type'] as String? ??
          'CAR',
    );
  }
}
