import 'package:equatable/equatable.dart';

/// Entidad pura de vehículo de usuario (UserCar) para la capa de dominio.
class UserCar extends Equatable {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String vehicleType;
  final String? brandLogoUrl;

  const UserCar({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.vehicleType = 'CAR',
    this.brandLogoUrl,
  });

  String get computedBrandLogoUrl {
    if (brandLogoUrl != null && brandLogoUrl!.isNotEmpty) return brandLogoUrl!;
    final normalized = brand.toLowerCase().replaceAll(RegExp(r'\s+'), '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/$normalized.png';
  }

  @override
  List<Object?> get props => [id, brand, model, year, vehicleType, brandLogoUrl];
}
