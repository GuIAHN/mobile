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
          Text('¿Para qué vehículo es?', style: AppTypography.h1),
          const SizedBox(height: 8),
          Text(
            'Elige el vehículo para mostrar repuestos compatibles.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text('TUS VEHÍCULOS', style: AppTypography.overline),
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
    final extraHeight = ((textScale - 1) * 72).clamp(0.0, 112.0);
    final cards = cars.length == 1
        ? SizedBox(
            height: 164 + extraHeight,
            child: _VehicleCard(
              car: cars.single,
              isSelected: _isSelected(cars.single),
              onTap: () => onVehicleSelected(cars.single),
            ),
          )
        : SizedBox(
            height: 178 + extraHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth * 0.84).clamp(256.0, 336.0);
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
            'Desliza para ver ' + cars.length.toString() + ' vehículos',
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
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    bottom: 4,
                    width: 190,
                    height: 128,
                    child: RepaintBoundary(
                      child: VehicleTypeIllustration(
                        vehicleType: car.vehicleType,
                        width: 190,
                        height: 128,
                        fit: BoxFit.contain,
                        showBackground: false,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BrandMark(car: car),
                          const Spacer(),
                          SizedBox(
                            width: 158,
                            child: Text(
                              car.brand + ' ' + car.model,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.title.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            car.year.toString() +
                                ' · ' +
                                _vehicleTypeLabel(car),
                            style: AppTypography.meta,
                          ),
                        ],
                      ),
                    ),
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
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : const SizedBox(
                              key: ValueKey('not-selected'),
                              width: 28,
                              height: 28,
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
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(7),
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
          size: 18,
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
