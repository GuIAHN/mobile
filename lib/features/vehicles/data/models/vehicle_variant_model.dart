import '../../domain/entities/vehicle_variant.dart';

/// Data model for vehicle variants with JSON serialization.
class VehicleVariantModel extends VehicleVariant {
  const VehicleVariantModel({
    required super.id,
    required super.modelId,
    required super.year,
    required super.motor,
  });

  factory VehicleVariantModel.fromJson(Map<String, dynamic> json) {
    return VehicleVariantModel(
      id: json['id'] as String,
      modelId: json['modelId'] as String? ?? json['model_id'] as String? ?? '',
      year: json['year'] as int,
      motor: json['motor'] as String? ?? '',
    );
  }
}
