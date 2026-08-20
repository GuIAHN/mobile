import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
          _EditProfileButton(
            onTap: isLoading ? null : () => _mostrarDialogoEdicion(context, ref),
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

  void _mostrarDialogoEdicion(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _EditProfileBottomSheet(user: user),
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

/// Botón de "Editar perfil" discreto en la esquina del header: solo un
/// ícono de lápiz sin relleno ni borde para no competir visualmente con el
/// avatar y el nombre. Pensado para no "molestar" en la vista, según lo
/// pedido, a diferencia de un botón grande o un pill con texto.
class _EditProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _EditProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Editar perfil',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.edit_outlined,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Hoja modal para editar los datos de contacto básicos (nombre y
/// teléfono), abierta desde [_EditProfileButton] en el header del perfil.
class _EditProfileBottomSheet extends ConsumerStatefulWidget {
  final User user;

  const _EditProfileBottomSheet({required this.user});

  @override
  ConsumerState<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState
    extends ConsumerState<_EditProfileBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        context.showSnackBar(next.errorMessage!, isError: true);
        ref.read(authProvider.notifier).clearError();
      } else if (previous?.status == AuthStatus.loading &&
          next.status == AuthStatus.authenticated &&
          next.errorMessage == null) {
        context.showSnackBar('Perfil actualizado correctamente.',
            isSuccess: true);
        Navigator.pop(context);
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Editar Perfil',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Actualiza tus datos de contacto básicos.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Nombre Completo',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !isLoading,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Ej. Juan Pérez',
                    hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 15, color: AppColors.textSecondary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorStyle: GoogleFonts.hankenGrotesk(fontSize: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre completo';
                    }
                    if (val.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                Text(
                  'Número de Teléfono',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  enabled: !isLoading,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.hankenGrotesk(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Ej. +50499887766',
                    hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 15, color: AppColors.textSecondary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    errorStyle: GoogleFonts.hankenGrotesk(fontSize: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa tu número de teléfono';
                    }
                    final phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');
                    if (!phoneRegex.hasMatch(val.trim())) {
                      return 'Formato de teléfono inválido (E.164: Ej. +50499887766)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.border, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.hankenGrotesk(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _guardarPerfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Guardar',
                                style: GoogleFonts.hankenGrotesk(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _guardarPerfil() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
          );
    }
  }
}

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
