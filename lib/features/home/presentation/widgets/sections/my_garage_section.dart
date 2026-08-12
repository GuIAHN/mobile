import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../vehicles/domain/entities/user_car.dart';
import '../../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../../../vehicles/presentation/widgets/vehicle_selection_modal.dart';
import '../../../../vehicles/presentation/widgets/_atoms/vehicle_type_illustration.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../spare_part_wizard/spare_part_wizard_page.dart';
import '../../providers/home_providers.dart';

/// Sección "Mi garage" del home: tarjetas horizontales de los vehículos
/// del usuario, con acceso rápido a buscar repuestos y gestionar el garage
/// (que redirige a la pestaña de Perfil, donde vive el CRUD completo).
class MyGarageSection extends ConsumerWidget {
  const MyGarageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCarsAsync = ref.watch(userCarsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi garage',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(homeTabProvider.notifier).state = 3;
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    'Gestionar',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        userCarsAsync.when(
          data: (cars) {
            if (cars.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AddVehicleCard(ref: ref),
              );
            }
            return SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cars.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _GarageCard(car: cars[index]),
              ),
            );
          },
          loading: () => SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const _GarageCardSkeleton(),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _GarageCard extends StatelessWidget {
  final UserCar car;

  const _GarageCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 90,
                  width: double.infinity,
                  color: AppColors.grey50,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: VehicleTypeIllustration(
                    vehicleType: car.vehicleType,
                    height: 74,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    showBackground: false,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SparePartWizardPage.show(context);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Buscar',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${car.brand} ${car.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${car.year}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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

class _GarageCardSkeleton extends StatelessWidget {
  const _GarageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _AddVehicleCard extends StatelessWidget {
  final WidgetRef ref;

  const _AddVehicleCard({required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirDialogoAgregarVehiculo(context, ref),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Agrega tu vehículo para buscar repuestos más rápido.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoAgregarVehiculo(BuildContext context, WidgetRef ref) async {
    final result = await VehicleSelectionModal.show(context);
    if (result != null) {
      if (!context.mounted) return;

      final addCarUseCase = ref.read(addCarToGarageUseCaseProvider);
      final saveResult = await addCarUseCase(
        variantId: result.variantId,
      );

      if (!context.mounted) return;
      saveResult.fold(
        (failure) {},
        (car) {
          ref.read(authProvider.notifier).addUserCar(car);
        },
      );
    }
  }
}
