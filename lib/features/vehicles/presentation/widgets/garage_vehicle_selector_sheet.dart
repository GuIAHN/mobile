import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/user_car.dart';
import '../providers/vehicle_providers.dart';
import 'vehicle_selection_modal.dart';
import '_atoms/vehicle_type_illustration.dart';

class VehicleSelectorResult {
  final UserCar car;
  final String? modelId;

  const VehicleSelectorResult({
    required this.car,
    this.modelId,
  });
}

class GarageVehicleSelectorSheet extends ConsumerWidget {
  final UserCar? selectedCar;

  const GarageVehicleSelectorSheet({
    super.key,
    this.selectedCar,
  });

  /// Abre el modal y muestra la lista de selección.
  static Future<VehicleSelectorResult?> show(
    BuildContext context, {
    UserCar? selectedCar,
  }) {
    return showModalBottomSheet<VehicleSelectorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GarageVehicleSelectorSheet(selectedCar: selectedCar),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garageCarsAsync = ref.watch(userCarsProvider);
    final currentVehicle = selectedCar;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 26,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            'Selecciona un vehículo',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: garageCarsAsync.when(
              data: (garageCars) {
                if (garageCars.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No tienes vehículos en tu garaje.',
                        style: GoogleFonts.hankenGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: garageCars.length,
                  itemBuilder: (context, index) {
                    final car = garageCars[index];
                    final esSeleccionado = currentVehicle?.id == car.id &&
                        currentVehicle?.brand == car.brand &&
                        currentVehicle?.model == car.model &&
                        currentVehicle?.year == car.year;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: esSeleccionado
                                ? AppColors.primary
                                : AppColors.border,
                            width: esSeleccionado ? 1.5 : 1.0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(
                              context,
                              VehicleSelectorResult(car: car),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: esSeleccionado
                                        ? AppColors.primaryMuted
                                        : AppColors.grey50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: esSeleccionado
                                          ? AppColors.primary
                                              .withValues(alpha: 0.3)
                                          : AppColors.border,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: VehicleTypeIllustration(
                                    vehicleType: car.vehicleType,
                                    height: 48,
                                    width: 72,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Image.network(
                                            car.computedBrandLogoUrl,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox.shrink(),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '${car.brand} ${car.model}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.hankenGrotesk(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14.5,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Año ${car.year}',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (esSeleccionado)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error al cargar vehículos: $err',
                  style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await VehicleSelectionModal.show(context);
                if (result != null) {
                  final newCar = UserCar(
                    id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                    brand: result.brand.name,
                    model: result.modelName,
                    year: result.year,
                    modelId: result.modelId,
                    motor: result.motor,
                    vehicleType: result.vehicleType,
                  );
                  if (context.mounted) {
                    Navigator.pop(
                      context,
                      VehicleSelectorResult(
                        car: newCar,
                        modelId: result.modelId,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                'Buscar otro modelo...',
                style: GoogleFonts.hankenGrotesk(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
