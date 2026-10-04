import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_decorations.dart';
import '../../../../../../core/theme/app_icons.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../core/utils/formatters.dart';

class BillingBalanceCard extends StatelessWidget {
  const BillingBalanceCard({
    super.key,
    required this.amount,
  });

  final double? amount;

  @override
  Widget build(BuildContext context) {
    final isAvailable = amount != null;
    final isPaidUp = isAvailable && amount! <= 0;
    final formattedAmount = isAvailable
        ? Formatters.currency(amount!.clamp(0, double.infinity).toDouble())
        : 'No disponible';
    final statusText = switch ((isAvailable, isPaidUp)) {
      (false, _) => 'No pudimos obtener el saldo en este momento',
      (true, true) => 'Estás al día',
      (true, false) => 'Comisión pendiente por ventas realizadas en la app',
    };
    final statusLabel = switch ((isAvailable, isPaidUp)) {
      (false, _) => 'SIN DATOS',
      (true, true) => 'AL DÍA',
      (true, false) => 'PENDIENTE',
    };
    final statusIcon = switch ((isAvailable, isPaidUp)) {
      (false, _) => AppIcons.info,
      (true, true) => AppIcons.success,
      (true, false) => AppIcons.receipt,
    };
    final statusColor = switch ((isAvailable, isPaidUp)) {
      (false, _) => AppColors.warningInk,
      (true, true) => AppColors.successInk,
      (true, false) => AppColors.textMeta,
    };
    final statusBackground = switch ((isAvailable, isPaidUp)) {
      (false, _) => AppColors.warningLight,
      (true, true) => AppColors.successLight,
      (true, false) => AppColors.primaryMuted,
    };
    final statusLabelColor = switch ((isAvailable, isPaidUp)) {
      (false, _) => AppColors.warningInk,
      (true, true) => AppColors.successInk,
      (true, false) => AppColors.textPrimary,
    };
    final usesLargeText = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3;

    final amountValue = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        formattedAmount,
        maxLines: 1,
        style: AppTypography.display.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
    final statusBadge = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        statusLabel,
        style: AppTypography.overline.copyWith(
          color: statusLabelColor,
          letterSpacing: 1,
        ),
      ),
    );

    return Semantics(
      container: true,
      label: 'Saldo pendiente con GuIA, $formattedAmount. $statusText',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('store-billing-balance-card'),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppDecorations.raised,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppSpacing.xs,
                  color: AppColors.primary,
                ),
              ),
              const Positioned(
                right: -8,
                top: 44,
                child: Opacity(
                  opacity: 0.045,
                  child: AppLineIcon(
                    AppIcons.balance,
                    size: AppIconSize.hero,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppLineIcon(
                          AppIcons.balance,
                          size: AppIconSize.leading,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Saldo pendiente con GuIA',
                            style: AppTypography.title.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (usesLargeText)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: double.infinity, child: amountValue),
                          const SizedBox(height: AppSpacing.sm),
                          statusBadge,
                        ],
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: amountValue),
                          const SizedBox(width: AppSpacing.md),
                          statusBadge,
                        ],
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppLineIcon(
                          statusIcon,
                          size: AppIconSize.action,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            statusText,
                            style: AppTypography.bodySm.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
