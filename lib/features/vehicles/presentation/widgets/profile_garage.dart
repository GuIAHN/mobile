import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/user_car.dart';
import '../providers/vehicle_providers.dart';
import 'vehicle_selection_modal.dart';
import '_atoms/vehicle_type_illustration.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileGarage extends ConsumerWidget {
  const ProfileGarage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listenAsyncError(userCarsProvider, context);
    final userCarsAsync = ref.watch(userCarsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila Encabezado Garage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_filled_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mi Garage',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            _PressableScale(
              onTap: () => _abrirDialogoAgregarVehiculo(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Listado de Autos
        userCarsAsync.when(
          data: (cars) {
            if (cars.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.no_crash_outlined, size: 36, color: AppColors.textDisabled),
                    const SizedBox(height: 10),
                    Text(
                      'Aún no tienes vehículos en tu garage.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: cars.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 230,
                    child: _buildGarageCarCard(context, ref, cars[index]),
                  );
                },
              ),
            );
          },
          loading: () => Container(
            height: 90,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Error al cargar vehículos: $err',
              style: GoogleFonts.hankenGrotesk(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGarageCarCard(BuildContext context, WidgetRef ref, UserCar car) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área Superior (Hero) — Gran espacio para la ilustración del vehículo
          Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              border: Border(
                bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    child: VehicleTypeIllustration(
                      vehicleType: car.vehicleType,
                      height: 105,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      showBackground: false,
                    ),
                  ),
                ),
                // Badge del Logo de Marca en la esquina superior izquierda
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.network(
                      car.computedBrandLogoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Badge del Año en la esquina superior derecha
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${car.year}',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Área Inferior — Nombre del Vehículo y Botón de Eliminar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.network(
                            car.computedBrandLogoUrl,
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${car.brand} ${car.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getVehicleTypeName(car.vehicleType),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PressableScale(
                  onTap: () => _confirmarEliminarVehiculo(context, ref, car),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeName(String type) {
    switch (type.toUpperCase()) {
      case 'SPORT':
      case 'SPORTS':
        return 'Deportivo';
      case 'SUV':
      case 'UTILITY':
        return 'Camioneta SUV';
      case 'PICKUP':
        return 'Pickup';
      case 'TRUCK':
      case 'LORRY':
        return 'Camión';
      case 'VAN':
      case 'MINIVAN':
        return 'Van / Minivan';
      case 'BUS':
      case 'COACH':
      case 'AUTOBUS':
        return 'Autobús';
      case 'MOTORCYCLE':
        return 'Motocicleta';
      case 'CAR':
      case 'SEDAN':
      default:
        return 'Turismo / Sedan';
    }
  }

  void _abrirDialogoAgregarVehiculo(BuildContext context, WidgetRef ref) async {
    final result = await VehicleSelectionModal.show(context);
    if (result != null) {
      if (!context.mounted) return;

      final addCarUseCase = ref.read(addCarToGarageUseCaseProvider);
      final saveResult = await addCarUseCase(
        variantId: result.variantId,
      );

      if (!context.mounted) return;
      saveResult.fold(
        (failure) {
          context.showSnackBar(
            'Error: ${failure.message}',
            isError: true,
          );
        },
        (car) {
          ref.read(authProvider.notifier).addUserCar(car);
          context.showSnackBar(
            '¡${car.brand} ${car.model} registrado exitosamente!',
            isSuccess: true,
          );
        },
      );
    }
  }

  void _confirmarEliminarVehiculo(BuildContext context, WidgetRef ref, UserCar car) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            '¿Eliminar vehículo?',
            style: GoogleFonts.hankenGrotesk(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar el ${car.brand} ${car.model} (${car.year}) de tu garage?',
            style: GoogleFonts.hankenGrotesk(
              color: AppColors.textSecondary,
              fontSize: 14.5,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Cierra diálogo primero

                      final deleteCarUseCase = ref.read(deleteCarUseCaseProvider);
                      final deleteResult = await deleteCarUseCase(car.id);

                      if (!context.mounted) return;
                      deleteResult.fold(
                        (failure) {
                          context.showSnackBar(
                            'Error: ${failure.message}',
                            isError: true,
                          );
                        },
                        (success) {
                          ref.read(authProvider.notifier).removeUserCar(car.id);
                          context.showSnackBar(
                            '¡Vehículo eliminado del garage!',
                            isSuccess: true,
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ===== Botón con efecto de escalado premium =====
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
