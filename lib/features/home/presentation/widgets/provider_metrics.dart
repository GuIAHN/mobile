import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/provider_detail.dart';

class ProviderMetrics extends StatelessWidget {
  final ProviderDetail detail;
  final double? distanceKm;
  final bool fullWidthForLargeText;

  const ProviderMetrics({
    super.key,
    required this.detail,
    this.distanceKm,
    this.fullWidthForLargeText = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayedDistanceKm = distanceKm ?? detail.distanciaKm;
    final hasRating =
        detail.rating != null && detail.rating! > 0 && detail.ratingCount > 0;
    final items = [
      _MetricData(
        icon: AppIcons.rating,
        iconColor: AppColors.warningInk,
        value: hasRating ? detail.rating!.toStringAsFixed(1) : 'Nuevo',
        label: hasRating
            ? '${detail.ratingCount} ${detail.ratingCount == 1 ? 'reseña' : 'reseñas'}'
            : 'Sin reseñas',
      ),
      _MetricData(
        icon: AppIcons.distance,
        iconColor: AppColors.primaryInk,
        value: displayedDistanceKm != null
            ? '${displayedDistanceKm.toStringAsFixed(1)} km'
            : 'Sin dato',
        label: 'Distancia',
      ),
      _MetricData(
        icon: AppIcons.price,
        iconColor: AppColors.successInk,
        value: detail.tarifa != null && detail.tarifa! > 0
            ? Formatters.currencyCompact(detail.tarifa!)
            : 'Consultar',
        label: detail.tarifa != null && detail.tarifa! > 0
            ? 'Tarifa / h'
            : 'Precios',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        if (constraints.maxWidth < 320 || textScale >= 1.6) {
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final item in items)
                SizedBox(
                  width: fullWidthForLargeText && textScale >= 1.6
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.sm) / 2,
                  child: _MetricTile(data: item, horizontal: true),
                ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                Expanded(child: _MetricTile(data: items[index])),
                if (index < items.length - 1)
                  const VerticalDivider(
                    width: AppSpacing.lg,
                    thickness: 1,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MetricData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
}

class _MetricTile extends StatelessWidget {
  final _MetricData data;
  final bool horizontal;

  const _MetricTile({required this.data, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          data.value,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: AppTypography.title,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          data.label,
          textAlign: horizontal ? TextAlign.left : TextAlign.center,
          style: AppTypography.meta,
        ),
      ],
    );

    return Semantics(
      label: '${data.value}, ${data.label}',
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.buttonHeightMd),
        padding:
            horizontal ? const EdgeInsets.all(AppSpacing.sm) : EdgeInsets.zero,
        decoration: horizontal
            ? BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              )
            : null,
        child: horizontal
            ? Row(
                children: [
                  AppLineIcon(
                    data.icon,
                    size: AppIconSize.action,
                    color: data.iconColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: content),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLineIcon(
                    data.icon,
                    size: AppIconSize.action,
                    color: data.iconColor,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  content,
                ],
              ),
      ),
    );
  }
}
