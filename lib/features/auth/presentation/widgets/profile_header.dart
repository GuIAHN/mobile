import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../provider_profile/presentation/providers/provider_profile_providers.dart';
import '../../../vehicles/presentation/providers/vehicle_providers.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class _RoleStyle {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _RoleStyle({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  factory _RoleStyle.of(UserRole role) {
    switch (role) {
      case UserRole.consumer:
        return const _RoleStyle(
          label: 'Consumidor',
          icon: Icons.person_rounded,
          color: AppColors.primary,
          bgColor: AppColors.primaryMuted,
        );
      case UserRole.mechanic:
        return const _RoleStyle(
          label: 'Mecánico',
          icon: Icons.build_rounded,
          color: AppColors.secondary,
          bgColor: AppColors.grey200,
        );
      case UserRole.store:
        return const _RoleStyle(
          label: 'Tienda',
          icon: Icons.storefront_rounded,
          color: AppColors.tertiary,
          bgColor: AppColors.tertiaryMuted,
        );
      case UserRole.workshop:
        return const _RoleStyle(
          label: 'Taller',
          icon: Icons.warehouse_rounded,
          color: AppColors.success,
          bgColor: AppColors.successLight,
        );
      case UserRole.admin:
        return const _RoleStyle(
          label: 'Administrador',
          icon: Icons.shield_rounded,
          color: AppColors.error,
          bgColor: AppColors.errorLight,
        );
      case UserRole.unknown:
        return const _RoleStyle(
          label: 'Usuario',
          icon: Icons.person_outline_rounded,
          color: AppColors.textSecondary,
          bgColor: AppColors.grey100,
        );
    }
  }
}

class ProfileHeader extends ConsumerWidget {
  final User user;

  const ProfileHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar errores para mostrar un SnackBar
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // Obtener iniciales
    final nameParts = user.name.trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts.isNotEmpty && nameParts[0].isNotEmpty
            ? nameParts[0][0].toUpperCase()
            : 'U';

    final roleStyle = _RoleStyle.of(user.role);

    // Resolver URL completa del avatar si existe
    final String? avatarUrl = user.avatarUrl;
    String? fullAvatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        fullAvatarUrl = avatarUrl;
      } else {
        final uri = Uri.parse(Env.baseUrl);
        final hostUrl = '${uri.scheme}://${uri.host}:${uri.port}';
        fullAvatarUrl = '$hostUrl$avatarUrl';
      }
    }

    Widget avatarChild;
    if (fullAvatarUrl != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Image.network(
          fullAvatarUrl,
          width: 84,
          height: 84,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                initials,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );
    } else {
      avatarChild = Text(
        initials,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryMuted, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.65],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          // Avatar con Iniciales / Foto + Carga + Botón de cámara
          Stack(
            children: [
              GestureDetector(
                onTap: isLoading ? null : () => _mostrarOpcionesImagen(context, ref),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: avatarChild,
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: isLoading ? null : () => _mostrarOpcionesImagen(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Información de texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Pill / Tag de Rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: roleStyle.bgColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleStyle.icon, size: 12, color: roleStyle.color),
                      const SizedBox(width: 5),
                      Text(
                        roleStyle.label.toUpperCase(),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: roleStyle.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          _ProfileStatsRow(user: user),
        ],
      ),
    );
  }

  void _mostrarOpcionesImagen(BuildContext context, WidgetRef ref) async {
    final source = await ImageSourceSelectorSheet.show(
      context,
      title: 'Actualizar Foto de Perfil',
    );
    if (source != null) {
      _pickImage(ref, source);
    }
  }

  Future<void> _pickImage(WidgetRef ref, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        await ref.read(authProvider.notifier).updateProfilePhoto(file.path);
      }
    } catch (e) {
      // Manejar error si es necesario
    }
  }
}

/// Fila de estadísticas rápidas del perfil: una métrica contextual al rol
/// (vehículos, especialidades o línea de venta, según corresponda) más el
/// estado de la cuenta. Reutiliza los providers ya existentes de cada
/// feature en vez de duplicar lógica de conteo.
class _ProfileStatsRow extends ConsumerWidget {
  final User user;

  const _ProfileStatsRow({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _StatData? roleStat;

    if (user.role.isMechanic || user.role.isWorkshop) {
      final specialtiesAsync = ref.watch(providerSpecialtiesProvider);
      roleStat = _StatData(
        icon: Icons.build_circle_rounded,
        value: specialtiesAsync.maybeWhen(
          data: (s) => '${s.length}',
          orElse: () => '—',
        ),
        label: 'Especialidades',
      );
    } else if (user.role.isStore) {
      final catalogAsync = ref.watch(storeCatalogProvider);
      roleStat = _StatData(
        icon: Icons.category_rounded,
        value: catalogAsync.maybeWhen(
          data: (l) => '${l.length}',
          orElse: () => '—',
        ),
        label: 'Líneas de venta',
      );
    } else if (user.role.isConsumer) {
      final carsAsync = ref.watch(userCarsProvider);
      roleStat = _StatData(
        icon: Icons.directions_car_filled_rounded,
        value: carsAsync.maybeWhen(
          data: (c) => '${c.length}',
          orElse: () => '—',
        ),
        label: 'Vehículos',
      );
    }

    final accountStat = _StatData(
      icon: Icons.verified_rounded,
      value: user.approved ? 'Activa' : 'Pendiente',
      label: 'Cuenta',
    );

    final stats = [if (roleStat != null) roleStat, accountStat];

    return Row(
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0)
            Container(
              width: 1,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.border,
            ),
          Expanded(child: _StatChip(stat: stats[i])),
        ],
      ],
    );
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;

  const _StatData({required this.icon, required this.value, required this.label});
}

class _StatChip extends StatelessWidget {
  final _StatData stat;

  const _StatChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.celesteMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(stat.icon, size: 16, color: AppColors.celesteInk),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stat.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                stat.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
