import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/env.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/image_source_selector_sheet.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/providers/auth_state.dart';

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

    // Determinar etiqueta y color de rol
    final String roleLabel;
    final Color roleColor;
    final Color roleBgColor;

    switch (user.role) {
      case UserRole.consumer:
        roleLabel = 'Consumidor';
        roleColor = AppColors.primary;
        roleBgColor = AppColors.primaryMuted;
        break;
      case UserRole.mechanic:
        roleLabel = 'Mecánico';
        roleColor = AppColors.secondary;
        roleBgColor = AppColors.grey200;
        break;
      case UserRole.store:
        roleLabel = 'Tienda';
        roleColor = const Color(0xFF3B82F6);
        roleBgColor = const Color(0xFFEFF6FF);
        break;
      case UserRole.workshop:
        roleLabel = 'Taller';
        roleColor = const Color(0xFF10B981);
        roleBgColor = const Color(0xFFECFDF5);
        break;
      case UserRole.admin:
        roleLabel = 'Administrador';
        roleColor = const Color(0xFFEF4444);
        roleBgColor = const Color(0xFFFEF2F2);
        break;
      default:
        roleLabel = 'Usuario';
        roleColor = AppColors.textSecondary;
        roleBgColor = AppColors.grey100;
    }

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
          width: 68,
          height: 68,
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
        color: Colors.white,
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
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar con Iniciales / Foto + Carga + Botón de cámara
          Stack(
            children: [
              GestureDetector(
                onTap: isLoading ? null : () => _mostrarOpcionesImagen(context, ref),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
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
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.email,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Pill / Tag de Rol
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleBgColor,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
