import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_icons.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';

/// Aviso temporal mientras se incorporan tiendas de repuestos.
class SparePartsAvailabilityDialog extends StatelessWidget {
  const SparePartsAvailabilityDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        animationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (_) => const SparePartsAvailabilityDialog(),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.xl2),
      scrollable: true,
      icon: const ExcludeSemantics(
        child: AppLineIcon(
          AppIcons.catalog,
          size: AppIconSize.feature,
          color: AppColors.primary,
        ),
      ),
      title: Text(
        'Próximamente',
        textAlign: TextAlign.center,
        style: AppTypography.h2,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Estamos en etapa de captación de tiendas de repuestos.',
            textAlign: TextAlign.center,
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'La opción «Pedir repuesto» se habilitará el 19 de octubre.',
            textAlign: TextAlign.center,
            style: AppTypography.title,
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl2,
        0,
        AppSpacing.xl2,
        AppSpacing.xl2,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.all(AppSpacing.lg),
              shape: const StadiumBorder(),
            ),
            child: Text('ENTENDIDO', style: AppTypography.label),
          ),
        ),
      ],
    );
  }
}
