import 'package:equatable/equatable.dart';

/// Entidad pura de vehículo de usuario (UserCar) para la capa de dominio.
class UserCar extends Equatable {
  final String id;
  final String modelId;
  final String brand;
  final String model;
  final int year;
  final String? motor;
  final String vehicleType;
  final String? brandLogoUrl;

  const UserCar({
    required this.id,
    this.modelId = '',
    required this.brand,
    required this.model,
    required this.year,
    String? motor,
    @Deprecated('Use motor instead') String? version,
    this.vehicleType = 'CAR',
    this.brandLogoUrl,
  }) : motor = motor ?? version;

  @Deprecated('Use motor instead')
  String? get version => motor;

  String get computedBrandLogoUrl {
    if (brandLogoUrl != null && brandLogoUrl!.isNotEmpty) return brandLogoUrl!;
    final normalized = brand
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9-]'), '');
    return 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/$normalized.png';
  }

  @override
  List<Object?> get props => [
        id,
        modelId,
        brand,
        model,
        year,
        motor,
        vehicleType,
        brandLogoUrl,
      ];
}
