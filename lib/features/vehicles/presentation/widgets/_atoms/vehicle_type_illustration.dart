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
    const assetRoot = 'assets/images/vehicles/v3';
    final t = type.trim().toUpperCase();
    switch (t) {
      case 'SPORT':
      case 'SPORTS':
        return '$assetRoot/sport.webp';
      case 'SUV':
      case 'UTILITY':
        return '$assetRoot/suv.webp';
      case 'PICKUP':
      case 'TRUCK':
        return '$assetRoot/pickup.webp';
      case 'VAN':
      case 'MINIVAN':
        return '$assetRoot/van.webp';
      case 'MOTORCYCLE':
      case 'MOTO':
        return '$assetRoot/motorcycle.webp';
      case 'COMPACT':
      case 'HATCHBACK':
        return '$assetRoot/compact.webp';
      case 'CAR':
      case 'SEDAN':
      default:
        return '$assetRoot/sedan.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = getAssetPath(vehicleType);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width.isFinite && width > 0
            ? width
            : constraints.hasBoundedWidth
                ? constraints.maxWidth
                : 240.0;
        final resolvedHeight = height.isFinite && height > 0
            ? height
            : constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 120.0;
        final decodeWidth =
            (resolvedWidth * pixelRatio).round().clamp(240, 1024);

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
            width: resolvedWidth,
            height: resolvedHeight,
            child: img,
          );
        }

        return Container(
          width: resolvedWidth,
          height: resolvedHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: img,
        );
      },
    );
  }
}
