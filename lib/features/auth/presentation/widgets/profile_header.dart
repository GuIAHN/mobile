import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/utils/venezuelan_phone_number.dart';
import '../../../../shared/widgets/app_phone_field.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';

class _RoleStyle {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  const _RoleStyle({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.icon,
  });

  factory _RoleStyle.of(UserRole role) {
    switch (role) {
      case UserRole.consumer:
        return const _RoleStyle(
          label: 'Consumidor',
          bgColor: AppColors.primaryMuted,
          textColor: AppColors.primary,
          icon: Icons.person_outline_rounded,
        );
      case UserRole.mechanic:
        return const _RoleStyle(
          label: 'Mecánico',
          bgColor: AppColors.grey200,
          textColor: AppColors.grey800,
          icon: Icons.build_outlined,
        );
      case UserRole.store:
        return const _RoleStyle(
          label: 'Tienda',
          bgColor: AppColors.tertiaryMuted,
          textColor: AppColors.tertiary,
          icon: Icons.storefront_outlined,
        );
      case UserRole.workshop:
        return const _RoleStyle(
          label: 'Taller',
          bgColor: AppColors.successLight,
          textColor: AppColors.successInk,
          icon: Icons.garage_outlined,
        );
      case UserRole.admin:
        return const _RoleStyle(
          label: 'Administrador',
          bgColor: AppColors.errorLight,
          textColor: AppColors.errorInk,
          icon: Icons.admin_panel_settings_outlined,
        );
      case UserRole.unknown:
        return const _RoleStyle(
          label: 'Usuario',
          bgColor: AppColors.grey100,
          textColor: AppColors.textPrimary,
          icon: Icons.person_outline_rounded,
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
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final fullAvatarUrl = resolveMediaUrl(user.avatarUrl);

    Widget avatarChild;
    if (fullAvatarUrl != null) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Image.network(
          fullAvatarUrl,
          width: 96,
          height: 96,
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
                  fontSize: 26,
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
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      );
    }

    final avatarAction =
        isLoading ? null : () => _mostrarOpcionesImagen(context, ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 4, 48, 0),
              child: Column(
                children: [
                  Semantics(
                    button: true,
                    enabled: avatarAction != null,
                    label: isLoading
                        ? 'Actualizando foto de perfil'
                        : 'Cambiar foto de perfil',
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const Key('change-profile-photo'),
                        onTap: avatarAction,
                        customBorder: const CircleBorder(),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.22),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: avatarChild,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.surface,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 21,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: roleStyle.bgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleStyle.textColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          roleStyle.icon,
                          size: 14,
                          color: roleStyle.textColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            roleStyle.label.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: roleStyle.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: _EditProfileButton(
                onTap: isLoading
                    ? null
                    : () => _mostrarDialogoEdicion(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'INFORMACIÓN DE CONTACTO',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _ContactInfoPanel(user: user),
      ],
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

class _ContactInfoPanel extends StatelessWidget {
  final User user;

  const _ContactInfoPanel({required this.user});

  @override
  Widget build(BuildContext context) {
    final phone = user.phone?.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _ContactInfoRow(
            icon: Icons.smartphone_outlined,
            label: 'TELÉFONO',
            value: phone == null || phone.isEmpty
                ? 'Sin número registrado'
                : phone,
            isMuted: phone == null || phone.isEmpty,
          ),
          const Divider(
              height: 1, indent: 16, endIndent: 16, color: AppColors.border),
          _ContactInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'CORREO ELECTRÓNICO',
            value: user.email,
          ),
        ],
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMuted;

  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: isMuted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
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

/// Botón de acción circular con icono para editar el perfil.
class _EditProfileButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _EditProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Editar perfil',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          key: const Key('edit-profile'),
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.edit_outlined,
              size: 22,
              color: onTap == null
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
            ),
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: AppColors.grey50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
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
                AppPhoneField(
                  label: 'NÚMERO DE TELÉFONO',
                  controller: _phoneController,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.done,
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
            phone: VenezuelanPhoneNumber.toApi(_phoneController.text),
          );
    }
  }
}
