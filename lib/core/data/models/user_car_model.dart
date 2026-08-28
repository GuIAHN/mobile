import '../../domain/entities/user_car.dart';

/// API representation of a garage vehicle shared by auth and vehicles.
class UserCarModel extends UserCar {
  final String? placa;
  final String? color;

  const UserCarModel({
    required super.id,
    super.modelId,
    required super.brand,
    required super.model,
    required super.year,
    super.motor,
    super.vehicleType = 'CAR',
    super.brandLogoUrl,
    this.placa,
    this.color,
  });

  factory UserCarModel.fromJson(Map<String, dynamic> json) {
    final modelMap = json['model'] as Map<String, dynamic>? ?? const {};
    final brandMap = modelMap['brand'] as Map<String, dynamic>? ?? const {};
    return UserCarModel(
      id: json['id'] as String,
      modelId: json['modelId'] as String? ?? modelMap['id'] as String? ?? '',
      brand: brandMap['name'] as String? ?? '',
      model: modelMap['name'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      motor: json['motor'] as String?,
      vehicleType: modelMap['vehicleType'] as String? ?? 'CAR',
      brandLogoUrl: brandMap['photoUrl'] as String?,
      placa: json['placa'] as String?,
      color: json['color'] as String?,
    );
  }
}
