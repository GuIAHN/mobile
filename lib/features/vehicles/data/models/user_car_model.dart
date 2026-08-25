import '../../domain/entities/user_car.dart';

/// Data model for cars stored in the user's garage.
/// Maps the nested structure returned by the backend (UserCar -> Variant -> Model -> Brand).
class UserCarModel extends UserCar {
  final String? placa;
  final String? color;

  const UserCarModel({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
    super.vehicleType = 'CAR',
    super.brandLogoUrl,
    this.placa,
    this.color,
  });

  factory UserCarModel.fromJson(Map<String, dynamic> json) {
    // 3-table structure: variant -> model -> brand
    final variantMap = json['variant'] as Map<String, dynamic>?;

    if (variantMap != null) {
      final modelMap = variantMap['model'] as Map<String, dynamic>? ?? {};
      final brandMap = modelMap['brand'] as Map<String, dynamic>? ?? {};
      return UserCarModel(
        id: json['id'] as String,
        brand: brandMap['name'] as String? ?? '',
        model: modelMap['name'] as String? ?? '',
        year: variantMap['year'] as int? ?? 0,
        vehicleType: modelMap['vehicleType'] as String? ?? 'CAR',
        brandLogoUrl: brandMap['photoUrl'] as String?,
        placa: json['placa'] as String?,
        color: json['color'] as String?,
      );
    }

    // Legacy fallback (2-table structure: model -> brand)
    final modelMap = json['model'] as Map<String, dynamic>? ?? {};
    final brandMap = modelMap['brand'] as Map<String, dynamic>? ?? {};

    return UserCarModel(
      id: json['id'] as String,
      brand: brandMap['name'] as String? ?? '',
      model: modelMap['name'] as String? ?? '',
      year: modelMap['year'] as int? ?? 0,
      vehicleType: modelMap['vehicleType'] as String? ?? 'CAR',
      brandLogoUrl: brandMap['photoUrl'] as String?,
      placa: json['placa'] as String?,
      color: json['color'] as String?,
    );
  }

}
