part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep1 extends ConsumerWidget {
  final UserCar? selectedCar;
  final void Function(UserCar car, [String? modelId]) onVehicleSelected;

  const _SparePartWizardStep1({
    super.key,
    required this.selectedCar,
    required this.onVehicleSelected,
  });

  Future<void> _handleManualVehicleAdd(BuildContext context) async {
    final result = await VehicleSelectionModal.show(context);
    if (result == null) return;
    onVehicleSelected(
      UserCar(
        id: 'temp-' + DateTime.now().millisecondsSinceEpoch.toString(),
        brand: result.brand.name,
        model: result.modelName,
        year: result.year,
      ),
      result.modelId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCarsAsync = ref.watch(userCarsProvider);

    return SingleChildScrollView(
      key: const PageStorageKey('spare-wizard-step-1'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WizardStepIntro(
            icon: Icons.directions_car_outlined,
            eyebrow: 'COMPATIBILIDAD',
            title: 'Elige tu vehículo',
            description:
                'Usaremos este vehículo para encontrar piezas compatibles.',
          ),
          const SizedBox(height: 24),
          const _WizardSectionHeader(
            icon: Icons.garage_outlined,
            title: 'Tus vehículos',
            helper: 'Selecciona el vehículo para esta solicitud',
          ),
          const SizedBox(height: 12),
          userCarsAsync.when(
            data: (cars) {
              final displayCars = <UserCar>[...cars];
              if (selectedCar != null &&
                  !displayCars.any((car) => car.id == selectedCar!.id)) {
                displayCars.insert(0, selectedCar!);
              }
              return _buildGarage(context, displayCars, cars.isEmpty);
            },
            loading: () => const SkeletonBox(
              height: 164,
              borderRadius: AppSpacing.radiusXl,
            ),
            error: (_, __) => ErrorView(
              message: 'No pudimos cargar tus vehículos.',
              onRetry: () => ref.invalidate(userCarsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarage(
    BuildContext context,
    List<UserCar> cars,
    bool garageWasEmpty,
  ) {
    if (cars.isEmpty) {
      return _EmptyGarage(
        onAdd: () => _handleManualVehicleAdd(context),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extraHeight = ((textScale - 1) * 76).clamp(0.0, 120.0);
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    final singleCardWidth = availableWidth.clamp(228.0, 252.0);
    final cards = cars.length == 1
        ? Center(
            child: SizedBox(
              width: singleCardWidth,
              height: 300 + extraHeight,
              child: _VehicleCard(
                car: cars.single,
                isSelected: _isSelected(cars.single),
                onTap: () => onVehicleSelected(cars.single),
              ),
            ),
          )
        : SizedBox(
            height: 312 + extraHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth * 0.68).clamp(218.0, 252.0);
                return ListView.separated(
                  key: const PageStorageKey('wizard-vehicle-carousel'),
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  itemCount: cars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => SizedBox(
                    width: cardWidth,
                    child: _VehicleCard(
                      car: cars[index],
                      isSelected: _isSelected(cars[index]),
                      onTap: () => onVehicleSelected(cars[index]),
                    ),
                  ),
                );
              },
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        cards,
        if (cars.length > 1) ...[
          const SizedBox(height: 10),
          Text(
            'Desliza para comparar tus ${cars.length} vehículos',
            style: AppTypography.meta,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _handleManualVehicleAdd(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text(
              garageWasEmpty ? 'Agregar vehículo' : 'Usar otro vehículo',
              style: AppTypography.label,
            ),
          ),
        ),
      ],
    );
  }

  bool _isSelected(UserCar car) {
    return selectedCar?.id == car.id ||
        (selectedCar?.brand == car.brand &&
            selectedCar?.model == car.model &&
            selectedCar?.year == car.year);
  }
}

class _VehicleCard extends StatefulWidget {
  final UserCar car;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<_VehicleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final car = widget.car;
    final semantics = car.brand +
        ' ' +
        car.model +
        ', año ' +
        car.year.toString() +
        (widget.isSelected ? ', seleccionado' : '');

    return Semantics(
      button: true,
      selected: widget.isSelected,
      label: semantics,
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primaryMuted.withValues(alpha: 0.58)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: widget.isSelected ? 18 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (mounted) setState(() => _pressed = value);
              },
              child: Column(
                children: [
                  Expanded(
                    flex: 55,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 28, 14, 4),
                            child: RepaintBoundary(
                              child: VehicleTypeIllustration(
                                vehicleType: car.vehicleType,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                showBackground: false,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: _BrandMark(car: car),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedSwitcher(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            child: widget.isSelected
                                ? Container(
                                    key: const ValueKey('selected'),
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 19,
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('not-selected'),
                                    width: 30,
                                    height: 30,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: widget.isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : AppColors.border,
                  ),
                  Expanded(
                    flex: 45,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car.brand} ${car.model}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Año ${car.year} · ${_vehicleTypeLabel(car)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.meta,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _vehicleTypeLabel(UserCar car) {
    return switch (car.vehicleType.toUpperCase()) {
      'SUV' || 'UTILITY' => 'SUV',
      'PICKUP' || 'TRUCK' => 'Pickup',
      'VAN' || 'MINIVAN' => 'Van',
      'MOTORCYCLE' || 'MOTO' => 'Moto',
      'SPORT' || 'SPORTS' => 'Deportivo',
      'COMPACT' => 'Compacto',
      'HATCHBACK' => 'Hatchback',
      _ => 'Sedán',
    };
  }
}

class _BrandMark extends StatelessWidget {
  final UserCar car;
  const _BrandMark({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Image.network(
        car.computedBrandLogoUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.directions_car_rounded,
          color: AppColors.primary,
          size: 25,
        ),
      ),
    );
  }
}

class _EmptyGarage extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGarage({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.garage_outlined,
            color: AppColors.primary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text('Aún no tienes vehículos', style: AppTypography.title),
          const SizedBox(height: 4),
          Text(
            'Agrega uno para encontrar piezas compatibles.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar vehículo'),
            ),
          ),
        ],
      ),
    );
  }
}
