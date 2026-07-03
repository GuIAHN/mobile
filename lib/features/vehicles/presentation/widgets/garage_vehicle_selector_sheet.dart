import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/user_car.dart';
import '../providers/vehicle_providers.dart';
import 'vehicle_selection_modal.dart';

class GarageVehicleSelectorSheet extends ConsumerWidget {
  const GarageVehicleSelectorSheet({super.key});

  /// Abre el modal y muestra la lista de selección.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GarageVehicleSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garageCarsAsync = ref.watch(userCarsProvider);
    final currentVehicle = ref.watch(searchVehicleProvider);

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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: esSeleccionado ? AppColors.primary : AppColors.border,
                          width: esSeleccionado ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: esSeleccionado ? AppColors.primaryMuted : AppColors.grey100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: esSeleccionado ? AppColors.primary : AppColors.textSecondary,
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
                          ),
                        ),
                        trailing: esSeleccionado
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () {
                          ref.read(searchVehicleModelIdProvider.notifier).state = null;
                          ref.read(searchVehicleProvider.notifier).state = car;
                          Navigator.pop(context);
                        },
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
                Navigator.pop(context); // close this sheet
                final result = await VehicleSelectionModal.show(context);
                if (result != null) {
                  final newCar = UserCar(
                    id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                    brand: result.brand.name,
                    model: result.modelName,
                    year: result.year,
                  );
                  ref.read(searchVehicleModelIdProvider.notifier).state = result.modelId;
                  ref.read(searchVehicleProvider.notifier).state = newCar;
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
