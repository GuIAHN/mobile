import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/entities/user_car.dart';
import '../../../vehicles/presentation/widgets/garage_vehicle_selector_sheet.dart';
import '../providers/home_providers.dart';

/// Contexto vehicular opcional para las listas de talleres y mecánicos.
///
/// La tarjeta permite elegir el vehículo que se incluirá al contactar a un
/// proveedor, sin presentarlo como un filtro ni alterar los resultados.
class VehicleContextCard extends ConsumerWidget {
  const VehicleContextCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(searchVehicleProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: Material(
        key: const Key('vehicle-context-card'),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.grey300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _VehicleSummary(vehicle: vehicle)),
              const SizedBox(width: AppSpacing.md),
              _VehicleAction(
                onPressed: () => _selectVehicle(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectVehicle(BuildContext context, WidgetRef ref) async {
    final result = await GarageVehicleSelectorSheet.show(
      context,
      selectedCar: ref.read(searchVehicleProvider),
    );
    if (result == null || !context.mounted) return;

    HapticFeedback.selectionClick();
    ref.read(searchVehicleModelIdProvider.notifier).state = result.modelId;
    ref.read(searchVehicleProvider.notifier).state = result.car;
  }
}

class _VehicleSummary extends StatelessWidget {
  final UserCar? vehicle;

  const _VehicleSummary({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final selectedVehicle = vehicle;
    final version = selectedVehicle?.version?.trim();
    final semanticsLabel = selectedVehicle == null
        ? 'No hay un vehículo seleccionado'
        : 'Vehículo seleccionado: ${selectedVehicle.brand} '
            '${selectedVehicle.model}, año ${selectedVehicle.year}, '
            'versión ${version == null || version.isEmpty ? 'no especificada' : version}';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppLineIcon(
              AppIcons.vehicle,
              size: AppIconSize.feature,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedVehicle != null) ...[
                    Text('TU VEHÍCULO', style: AppTypography.overline),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    selectedVehicle == null
                        ? 'Selecciona el vehículo'
                        : '${selectedVehicle.brand} ${selectedVehicle.model}',
                    style: AppTypography.title,
                  ),
                  if (selectedVehicle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Año ${selectedVehicle.year} · Versión '
                      '${version == null || version.isEmpty ? 'no especificada' : version}',
                      style: AppTypography.bodySm,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _VehicleAction({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Elegir vehículo',
      excludeSemantics: true,
      child: TextButton(
        key: const Key('vehicle-context-action'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(
            AppSpacing.buttonHeightMd,
            AppSpacing.buttonHeightMd,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Elegir',
          style: AppTypography.label.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
