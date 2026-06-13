import '../../domain/entities/user_car.dart';

/// Modelo de UserCar que conoce la serialización JSON.
class UserCarModel extends UserCar {
  const UserCarModel({
    required super.id,
    required super.brand,
    required super.model,
    required super.year,
  });

  factory UserCarModel.fromJson(Map<String, dynamic> json) {
    return UserCarModel(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'year': year,
      };
}
