import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

/// Componente para renderizar la ilustración del tipo de vehículo
/// (Sedan, SUV, Deportivo, Pickup, Van, Motocicleta) con estilo uniforme.
class VehicleTypeIllustration extends StatelessWidget {
  final String vehicleType;
  final double height;
  final double width;
  final BoxFit fit;
  final bool showBackground;

  const VehicleTypeIllustration({
    super.key,
    required this.vehicleType,
    this.height = 75,
    this.width = 120,
    this.fit = BoxFit.contain,
    this.showBackground = true,
  });

  static String getAssetPath(String type) {
    final t = type.toUpperCase();
    switch (t) {
      case 'SPORT':
      case 'SPORTS':
        return 'assets/images/vehicles/v2/sport.webp';
      case 'SUV':
      case 'UTILITY':
        return 'assets/images/vehicles/v2/suv.webp';
      case 'PICKUP':
      case 'TRUCK':
        return 'assets/images/vehicles/v2/pickup.webp';
      case 'VAN':
      case 'MINIVAN':
        return 'assets/images/vehicles/v2/van.webp';
      case 'MOTORCYCLE':
      case 'MOTO':
        return 'assets/images/vehicles/v2/motorcycle.webp';
      case 'COMPACT':
      case 'HATCHBACK':
        return 'assets/images/vehicles/v2/compact.webp';
      case 'CAR':
      case 'SEDAN':
      default:
        return 'assets/images/vehicles/v2/sedan.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getAssetPath(vehicleType);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final decodeWidth = (width * pixelRatio).round().clamp(240, 1024);

    final img = Image.asset(
      assetPath,
      fit: fit,
      cacheWidth: decodeWidth,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(
          Icons.directions_car_rounded,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );

    if (!showBackground) {
      return SizedBox(
        width: width,
        height: height,
        child: img,
      );
    }

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: img,
    );
  }
}
