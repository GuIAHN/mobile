part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep1 extends ConsumerWidget {
  final UserCar? selectedCar;
  final void Function(UserCar car, [String? modelId]) onVehicleSelected;

  const _SparePartWizardStep1({
    super.key,
    required this.selectedCar,
    required this.onVehicleSelected,
  });

  void _handleManualVehicleAdd(BuildContext context) async {
    final result = await VehicleSelectionModal.show(context);
    if (result != null) {
      final newCar = UserCar(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        brand: result.brand.name,
        model: result.modelName,
        year: result.year,
      );
      onVehicleSelected(newCar, result.modelId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCarsAsync = ref.watch(userCarsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Para qué vehículo es?',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona un vehículo de tu garage para cotizar repuestos compatibles.',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Tus Vehículos',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          userCarsAsync.when(
            data: (cars) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No tienes vehículos registrados en tu garaje.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...cars.map((car) {
                      final isSelected = selectedCar?.id == car.id;
                      return _VehicleCard(
                        car: car,
                        isSelected: isSelected,
                        onTap: () => onVehicleSelected(car),
                      );
                    }),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 32),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleManualVehicleAdd(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(
                        cars.isEmpty ? 'Agregar vehículo' : 'Agregar otro vehículo',
                        style: GoogleFonts.hankenGrotesk(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final UserCar car;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.directions_car_rounded, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.brand} ${car.model}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${car.year}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            else
              const Icon(Icons.circle_outlined, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}
