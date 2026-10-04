import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/layout/bottom_navigation_insets.dart';

/// Bloquea las áreas operativas mientras la cuenta espera su eliminación.
///
/// La navegación inferior se pinta encima de esta capa para mantener accesible
/// la pestaña Perfil, donde vive la acción de restauración.
class PendingDeletionOverlay extends StatelessWidget {
  const PendingDeletionOverlay({
    required this.onOpenProfile,
    super.key,
  });

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final bottomInset = bottomNavigationContentInset(context) + AppSpacing.xl;

    return BlockSemantics(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: () {},
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.78),
              child: SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.xl,
                        AppSpacing.xl,
                        bottomInset,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: (constraints.maxHeight -
                                  bottomInset -
                                  (AppSpacing.xl * 2))
                              .clamp(0, double.infinity),
                        ),
                        child: Center(
                          child: Semantics(
                            container: true,
                            liveRegion: true,
                            label:
                                'Cuenta en proceso de eliminación. Ve al perfil para restaurarla.',
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 420),
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0D000000),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AppLineIcon(
                                    AppIcons.warning,
                                    size: AppIconSize.feature,
                                    color: AppColors.warningInk,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Tu cuenta está en proceso de eliminación',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.h2,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Para volver a utilizar la app, restáurala desde tu perfil antes de la fecha indicada.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySm,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      key: const Key(
                                        'pending-deletion-open-profile',
                                      ),
                                      onPressed: onOpenProfile,
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.md,
                                        ),
                                        backgroundColor: AppColors.primary,
                                        foregroundColor:
                                            AppColors.textOnPrimary,
                                        shape: const StadiumBorder(),
                                        textStyle: AppTypography.label,
                                      ),
                                      child: const Text('IR AL PERFIL'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
