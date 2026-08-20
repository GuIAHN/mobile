import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pressable_scale.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../provider_profile/presentation/widgets/provider_specialties_card.dart';
import '../../../provider_profile/presentation/widgets/store_catalog_card.dart';
import '../../../vehicles/presentation/widgets/profile_garage.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/security_section.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final isConsumer =
        user.role == UserRole.consumer || user.role == UserRole.unknown;
    final isProfessionalProvider =
        user.role == UserRole.mechanic || user.role == UserRole.workshop;

    final sections = <Widget>[
      // 1. Tarjeta Encabezado del Perfil (Avatar + Info + Teléfono + Stats)
      ProfileHeader(user: user),

      // 1b. Seguridad de la cuenta (cambiar contraseña), separado a
      // propósito del editor de datos básicos del header.
      const SecuritySection(),

      // 2. Sección "Mi Garage" (Solo para consumidores)
      if (isConsumer) const ProfileGarage(),

      // 4. Especialidades configurables (mecánicos y talleres)
      if (isProfessionalProvider) const ProviderSpecialtiesCard(),

      // 4b. Línea de venta (categorías y marcas) para tiendas de repuestos
      if (user.role.isStore) const StoreCatalogCard(),
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: 120,
        ),
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            StaggeredEntrance(index: i, child: sections[i]),
            SizedBox(height: i == 0 ? 20 : 24),
          ],

          // 5. Botón de Cerrar Sesión (separado visualmente de la navegación normal)
          const SizedBox(height: 4),
          _buildLogoutButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return PressableScale(
      onTap: () => _mostrarConfirmarLogout(context, ref),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'CERRAR SESIÓN',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmarLogout(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¿Cerrar Sesión?',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Deberás ingresar tus credenciales nuevamente para acceder a guIAutomotriz.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'CANCELAR',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Cierra modal
                          ref.read(authProvider.notifier).logout().then((_) {
                            if (context.mounted) {
                              context.go(RouteNames.login);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'CERRAR SESIÓN',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
