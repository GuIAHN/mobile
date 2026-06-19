import '../../domain/entities/user_car.dart';

/// Data model for cars stored in the user's garage.
/// Maps the nested structure returned by the backend (UserCar -> Model -> Brand).
class UserCarModel extends UserCar {
  final String? placa;
  final String? color;

  const UserCarModel({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
    this.placa,
    this.color,
  });

  factory UserCarModel.fromJson(Map<String, dynamic> json) {
    final modelMap = json['model'] as Map<String, dynamic>? ?? {};
    final brandMap = modelMap['brand'] as Map<String, dynamic>? ?? {};
    
    return UserCarModel(
      id: json['id'] as String,
      brand: brandMap['name'] as String? ?? '',
      model: modelMap['name'] as String? ?? '',
      year: modelMap['year'] as int? ?? 0,
      placa: json['placa'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
        if (placa != null) 'placa': placa,
        if (color != null) 'color': color,
      };
}
