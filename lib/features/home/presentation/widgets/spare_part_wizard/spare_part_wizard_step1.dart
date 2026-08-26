part of 'spare_part_wizard_page.dart';

class _SparePartWizardStep1 extends ConsumerStatefulWidget {
  final UserCar? selectedCar;
  final void Function(UserCar car, [String? modelId]) onVehicleSelected;

  const _SparePartWizardStep1({
    super.key,
    required this.selectedCar,
    required this.onVehicleSelected,
  });

  @override
  ConsumerState<_SparePartWizardStep1> createState() =>
      _SparePartWizardStep1State();
}

class _SparePartWizardStep1State extends ConsumerState<_SparePartWizardStep1> {
  late final PageController _vehiclePageController;
  final Set<String> _precachedAssets = <String>{};
  int _visibleVehicleIndex = 0;
  String? _garageSignature;

  @override
  void initState() {
    super.initState();
    _vehiclePageController = PageController(viewportFraction: 0.74);
  }

  @override
  void dispose() {
    _vehiclePageController.dispose();
    super.dispose();
  }

  Future<void> _handleManualVehicleAdd(BuildContext context) async {
    final result = await VehicleSelectionModal.show(context);
    if (result == null) return;
    widget.onVehicleSelected(
      UserCar(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        brand: result.brand.name,
        model: result.modelName,
        year: result.year,
        modelId: result.modelId,
        motor: result.motor,
        vehicleType: result.vehicleType,
      ),
      result.modelId,
    );
  }

  void _prepareGarage(List<UserCar> cars) {
    final signature = cars.map((car) => car.id).join('|');
    if (_garageSignature == signature) return;
    _garageSignature = signature;

    final selectedIndex = cars.indexWhere(_isSelected);
    final initialIndex = selectedIndex < 0 ? 0 : selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_visibleVehicleIndex != initialIndex) {
        setState(() => _visibleVehicleIndex = initialIndex);
      }
      if (_vehiclePageController.hasClients && cars.length > 1) {
        _vehiclePageController.jumpToPage(initialIndex);
      }
      _precacheVehicleTypes(cars);
    });
  }

  void _precacheVehicleTypes(List<UserCar> cars) {
    for (final car in cars) {
      final path = VehicleTypeIllustration.getAssetPath(car.vehicleType);
      if (!_precachedAssets.add(path)) continue;
      precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 28),
          const _WizardSectionHeader(
            icon: Icons.garage_outlined,
            title: 'Tus vehículos',
            helper: 'Selecciona el vehículo para esta solicitud',
          ),
          const SizedBox(height: 12),
          userCarsAsync.when(
            data: (cars) {
              final displayCars = <UserCar>[...cars];
              if (widget.selectedCar != null &&
                  !displayCars.any(
                    (car) => car.id == widget.selectedCar!.id,
                  )) {
                displayCars.insert(0, widget.selectedCar!);
              }
              _prepareGarage(displayCars);
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
      return _EmptyGarage(onAdd: () => _handleManualVehicleAdd(context));
    }

    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final extraHeight = ((textScale - 1) * 76).clamp(0.0, 120.0);
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    final singleCardWidth = availableWidth.clamp(228.0, 252.0);
    final visibleIndex = _visibleVehicleIndex.clamp(0, cars.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cars.length == 1)
          Center(
            child: SizedBox(
              width: singleCardWidth,
              height: 300 + extraHeight,
              child: _VehicleOptionCard(
                car: cars.single,
                isSelected: _isSelected(cars.single),
                onTap: () => widget.onVehicleSelected(cars.single),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 312 + extraHeight,
            child: PageView.builder(
              key: const PageStorageKey('wizard-vehicle-carousel'),
              controller: _vehiclePageController,
              clipBehavior: Clip.none,
              physics: const PageScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: cars.length,
              onPageChanged: (index) {
                if (_visibleVehicleIndex != index) {
                  setState(() => _visibleVehicleIndex = index);
                }
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _VehicleOptionCard(
                  car: cars[index],
                  isSelected: _isSelected(cars[index]),
                  onTap: () => widget.onVehicleSelected(cars[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VehicleCarouselIndicator(
            currentIndex: visibleIndex,
            total: cars.length,
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
    return widget.selectedCar?.id == car.id ||
        (widget.selectedCar?.brand == car.brand &&
            widget.selectedCar?.model == car.model &&
            widget.selectedCar?.year == car.year);
  }
}

class _VehicleCarouselIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _VehicleCarouselIndicator({
    required this.currentIndex,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Text(
              'Vehículo ${currentIndex + 1} de $total',
              key: ValueKey(currentIndex),
              style: AppTypography.meta.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(total, (index) {
            final active = index == currentIndex;
            return AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              width: active ? 18 : 6,
              height: 6,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.grey300,
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
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
