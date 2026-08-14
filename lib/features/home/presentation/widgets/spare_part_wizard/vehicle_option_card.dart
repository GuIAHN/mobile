part of 'spare_part_wizard_page.dart';

class _VehicleOptionCard extends StatefulWidget {
  final UserCar car;
  final bool isSelected;
  final VoidCallback onTap;

  const _VehicleOptionCard({
    required this.car,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_VehicleOptionCard> createState() => _VehicleOptionCardState();
}

class _VehicleOptionCardState extends State<_VehicleOptionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final car = widget.car;
    final semantics = '${car.brand} ${car.model}, año ${car.year}'
        '${widget.isSelected ? ', seleccionado' : ''}';

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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
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
                            padding: const EdgeInsets.fromLTRB(12, 30, 12, 2),
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
                          top: 10,
                          left: 10,
                          child: _VehicleBrandMark(car: car),
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

class _VehicleBrandMark extends StatelessWidget {
  final UserCar car;
  const _VehicleBrandMark({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExcludeSemantics(
        child: Image.network(
          car.computedBrandLogoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.directions_car_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),
      ),
    );
  }
}
