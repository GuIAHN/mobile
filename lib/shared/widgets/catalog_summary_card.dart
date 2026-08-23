import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'pressable_scale.dart';

/// Resumen compacto de una línea del catálogo.
///
/// Mantiene visibles los datos necesarios para escanear la lista y delega el
/// detalle completo de marcas al flujo que corresponda (edición o consulta).
class CatalogSummaryCard extends StatelessWidget {
  const CatalogSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.brandSummary,
    required this.sparePartTypes,
    required this.configured,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String brandSummary;
  final Iterable<String> sparePartTypes;
  final bool configured;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeSummary = sparePartTypes.isEmpty
        ? 'Sin tipos de repuesto'
        : sparePartTypes.map(catalogPartTypeLabel).join(' · ');
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final stateLabel = configured ? 'Configurada' : 'Sin configurar';

    return Semantics(
      button: true,
      label: '$title. $brandSummary. $typeSummary. $stateLabel. $actionLabel.',
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        scale: 0.97,
        child: AnimatedContainer(
          duration:
              reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: configured ? AppColors.primary : AppColors.border,
              width: configured ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.iconXl,
                height: AppSpacing.iconXl,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      configured ? AppColors.primaryMuted : AppColors.grey100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: AppSpacing.iconMd,
                  color:
                      configured ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(title, style: AppTypography.title),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          configured
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          size: AppSpacing.iconMd,
                          color: configured
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      brandSummary,
                      style: AppTypography.bodySm.copyWith(
                        color: configured
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(typeSummary, style: AppTypography.meta),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            actionLabel,
                            style: AppTypography.label.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: AppSpacing.iconSm,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String catalogPartTypeLabel(String type) {
  switch (type) {
    case 'ORIGINAL':
      return 'Original';
    case 'GENERIC':
      return 'Genérico';
    case 'PERFORMANCE':
      return 'Performance';
    default:
      return type;
  }
}
