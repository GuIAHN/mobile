import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: AppTypography.bodySm),
        ],
      ],
    );

    if (trailing == null) return heading;

    final usesLargeText = MediaQuery.textScalerOf(context).scale(18) > 24;
    if (usesLargeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          heading,
          const SizedBox(height: AppSpacing.md),
          Align(alignment: Alignment.centerLeft, child: trailing!),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: heading),
        const SizedBox(width: AppSpacing.md),
        trailing!,
      ],
    );
  }
}

class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      side: const BorderSide(color: AppColors.border),
    );

    return Semantics(
      button: true,
      label: 'Cambiar período. Selección actual: $label',
      child: Material(
        color: AppColors.surface,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLineIcon(
                    AppIcons.period,
                    size: AppIconSize.inline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const AppLineIcon(
                    AppIcons.expand,
                    size: AppIconSize.inline,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<int?> showDashboardPeriodBottomSheet(
  BuildContext context, {
  required int currentDays,
}) {
  return showModalBottomSheet<int>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: RoundedRectangleBorder(borderRadius: AppDecorations.sheet),
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.md),
        Container(
          width: AppSpacing.xl4,
          height: AppSpacing.xs,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Seleccionar período', style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),
        for (final days in const [7, 15, 30])
          ListTile(
            minTileHeight: 48,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
            ),
            onTap: () => Navigator.pop(context, days),
            title: Text(
              'Últimos $days días',
              style: AppTypography.body.copyWith(
                color: days == currentDays
                    ? AppColors.primary
                    : AppColors.textPrimary,
                fontWeight:
                    days == currentDays ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            trailing: days == currentDays
                ? const AppLineIcon(
                    AppIcons.selected,
                    size: AppIconSize.action,
                    color: AppColors.primary,
                    semanticLabel: 'Seleccionado',
                  )
                : null,
          ),
        const SizedBox(height: AppSpacing.lg),
      ],
    ),
  );
}
