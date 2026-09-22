import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

/// Acceso compacto del perfil, inspirado en la organización por módulos de la
/// referencia visual. Todo el contenedor es interactivo para ofrecer un área
/// táctil amplia y una lectura clara con tecnologías de asistencia.
class ProfileActionCard extends StatelessWidget {
  final Key? actionKey;
  final String semanticsLabel;
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData? icon;
  final int badgeCount;
  final VoidCallback onTap;

  const ProfileActionCard({
    super.key,
    this.actionKey,
    required this.semanticsLabel,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: InkWell(
                key: actionKey,
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 19,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ABRIR',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                key: const Key('profile-action-badge'),
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: badgeCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius:
                      badgeCount < 10 ? null : BorderRadius.circular(14),
                  border: Border.all(color: AppColors.background, width: 3),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
