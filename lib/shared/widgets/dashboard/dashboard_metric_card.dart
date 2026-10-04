import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Presentational KPI card shared by the app dashboards.
///
/// The component owns visual hierarchy, accessibility and comparison states;
/// callers provide only the business label, value and semantic accent.
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.deltaPct,
    this.helperText,
  });

  final IconData icon;
  final String label;
  final String value;
  final double? deltaPct;
  final Color accentColor;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final delta = deltaPct;
    final hasDirectionalDelta = delta != null && delta != 0;
    final isPositive = (delta ?? 0) > 0;
    final contextText = hasDirectionalDelta
        ? '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}% vs. período anterior'
        : delta == 0
            ? 'Sin cambios vs. período anterior'
            : helperText ?? _fallbackHelper(value);

    return Semantics(
      container: true,
      label: '$label, $value. $contextText',
      child: ExcludeSemantics(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDecorations.card,
            border: Border.all(color: AppColors.border),
            boxShadow: AppDecorations.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: AppSpacing.xl5,
                  height: AppSpacing.xs,
                  color: accentColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLineIcon(
                          icon,
                          size: AppIconSize.action,
                          color: accentColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hasDirectionalDelta)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppLineIcon(
                            isPositive ? AppIcons.trendUp : AppIcons.trendDown,
                            size: AppIconSize.inline,
                            color: isPositive
                                ? AppColors.successInk
                                : AppColors.errorInk,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              contextText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.meta.copyWith(
                                color: isPositive
                                    ? AppColors.successInk
                                    : AppColors.errorInk,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        contextText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.meta.copyWith(
                          color: AppColors.textMeta,
                          height: 1.25,
                        ),
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

  static String _fallbackHelper(String value) {
    final normalized = value.trim();
    if (normalized == '—' || normalized == 'No disponible') {
      return 'Dato no disponible';
    }

    final numeric = double.tryParse(
      normalized.replaceAll(RegExp(r'[^0-9.-]'), ''),
    );
    return numeric == 0 ? 'Sin datos este período' : 'Sin datos previos';
  }
}
