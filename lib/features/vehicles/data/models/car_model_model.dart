import '../../domain/entities/car_model.dart';

/// Vehicle model data model with JSON support.
class CarModelModel extends CarModel {
  const CarModelModel({
    required super.id,
    required super.brandId,
    required super.name,
    required super.motor,
    required super.year,
  });

  factory CarModelModel.fromJson(Map<String, dynamic> json) {
    return CarModelModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String? ?? json['brand_id'] as String? ?? '',
      name: json['name'] as String,
      motor: json['motor'] as String? ?? '',
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brandId': brandId,
        'name': name,
        'motor': motor,
        'year': year,
      };
}
