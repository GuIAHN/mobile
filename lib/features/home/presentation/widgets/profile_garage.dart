import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vehicles/domain/entities/user_car.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../core/utils/async_error_listener.dart';
import '../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';

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

            return Column(
              children: cars.map((car) => _buildGarageCarCard(car)).toList(),
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

  Widget _buildGarageCarCard(UserCar car) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: AppColors.primaryMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          '${car.brand} ${car.model}',
          style: GoogleFonts.hankenGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Año ${car.year}',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _abrirDialogoAgregarVehiculo(BuildContext context, WidgetRef ref) async {
    final result = await VehicleSelectionModal.show(context);
    if (result != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardando vehículo en tu garage...'),
          duration: Duration(seconds: 1),
        ),
      );

      final addCarUseCase = ref.read(addCarToGarageUseCaseProvider);
      final saveResult = await addCarUseCase(
        modelId: result.modelId,
      );

      if (!context.mounted) return;
      saveResult.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${failure.message}'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        (car) {
          ref.invalidate(userCarsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('¡${car.brand} ${car.model} registrado exitosamente!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      );
    }
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
