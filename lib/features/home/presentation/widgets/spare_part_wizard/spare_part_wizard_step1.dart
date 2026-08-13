part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep1 extends ConsumerWidget {
  final UserCar? selectedCar;
  final void Function(UserCar car, [String? modelId]) onVehicleSelected;
  final VoidCallback onNext;

  const _SparePartWizardStep1({
    super.key,
    required this.selectedCar,
    required this.onVehicleSelected,
    required this.onNext,
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
          Text('¿Para qué vehículo es?', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            'Selecciona un vehículo de tu garage para cotizar repuestos compatibles.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),

          Text(
            'Tus Vehículos',
            style: AppTypography.title.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 16),
          userCarsAsync.when(
            data: (cars) {
              final allDisplayCars = <UserCar>[...cars];
              if (selectedCar != null && !allDisplayCars.any((c) => c.id == selectedCar!.id)) {
                allDisplayCars.insert(0, selectedCar!);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allDisplayCars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text(
                        'No tienes vehículos registrados en tu garaje.',
                        style: AppTypography.bodySm,
                      ),
                    )
                  else ...[
                    SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        itemCount: allDisplayCars.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final car = allDisplayCars[index];
                          final isSelected = selectedCar?.id == car.id ||
                              (selectedCar?.brand == car.brand && selectedCar?.model == car.model && selectedCar?.year == car.year);
                          return SizedBox(
                            width: 230,
                            child: _VehicleCard(
                              car: car,
                              isSelected: isSelected,
                              onTap: () => onVehicleSelected(car),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      label: Text(
                        // Sin vehículos: se ofrece agregar el primero.
                        // Con al menos uno: se ofrece uno distinto a los ya listados.
                        cars.isEmpty ? 'Agregar vehículo' : 'Usar otro vehículo',
                        style: AppTypography.label.copyWith(fontSize: 14.5),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: selectedCar != null ? onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.grey200,
                        disabledForegroundColor: AppColors.textDisabled,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                        elevation: selectedCar != null ? 4 : 0,
                      ),
                      child: Text(
                        'Continuar',
                        style: AppTypography.label.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, __) => const SizedBox(
                  width: 230,
                  child: SkeletonBox(height: 220, borderRadius: AppSpacing.radiusXl),
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ErrorView(
                message: 'No pudimos cargar tus vehículos.',
                onRetry: () => ref.invalidate(userCarsProvider),
              ),
            ),
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
      child: Material(
        color: isSelected ? AppColors.primaryMuted.withValues(alpha: 0.25) : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        elevation: isSelected ? 3 : 1,
        shadowColor: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ilustración Hero + Marca/Check Badges
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
                  // Logo de la marca (Top Left)
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
                  // Estado de selección (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${car.year}',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Título + Modelo
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.network(
                        car.computedBrandLogoUrl,
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Año ${car.year}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
