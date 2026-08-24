import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_decorations.dart';
import '../../../../../../core/theme/app_icons.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';

class ContactChannelDatum {
  const ContactChannelDatum({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

/// Comparación de los canales que generan contactos para la tienda.
///
/// Usa barras verticales para mantener una lectura precisa por categoría y
/// diferenciarse del medidor radial de conversión que aparece más abajo.
class ContactChannelsChart extends StatelessWidget {
  const ContactChannelsChart({
    super.key,
    required this.channels,
  });

  final List<ContactChannelDatum> channels;

  @override
  Widget build(BuildContext context) {
    final total = channels.fold<int>(0, (sum, channel) => sum + channel.value);
    if (channels.isEmpty) {
      return const _ChartSurface(
        child: _UnavailableState(),
      );
    }
    if (total == 0) {
      return _ChartSurface(
        child: _ZeroContactsState(channels: channels),
      );
    }

    final rankedChannels = [...channels]
      ..sort((a, b) => b.value.compareTo(a.value));
    final leadingChannel = rankedChannels.first;
    final semanticSummary = rankedChannels
        .map((channel) => '${channel.label}: ${channel.value}')
        .join(', ');

    return Semantics(
      container: true,
      label:
          'Distribución de $total contactos. $semanticSummary. ${leadingChannel.label} es el canal principal.',
      child: ExcludeSemantics(
        child: _ChartSurface(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final stackedLegend =
                  constraints.maxWidth < 260 || textScale > 1.5;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartHeader(
                    total: total,
                    leadingChannel: leadingChannel,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    key: const Key('contact-channels-bar-chart'),
                    height: 190,
                    child: _ChannelBarChart(channels: rankedChannels),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ChannelLegend(
                    channels: rankedChannels,
                    itemWidth: stackedLegend
                        ? constraints.maxWidth
                        : (constraints.maxWidth - AppSpacing.sm) / 2,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChartSurface extends StatelessWidget {
  const _ChartSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('contact-channels-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDecorations.card,
          border: Border.all(color: AppColors.border),
          boxShadow: AppDecorations.soft,
        ),
        child: child,
      );
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.total,
    required this.leadingChannel,
  });

  final int total;
  final ContactChannelDatum leadingChannel;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLineIcon(
            AppIcons.contacts,
            size: AppIconSize.leading,
            color: AppColors.celesteInk,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total ${total == 1 ? 'contacto' : 'contactos'} registrados',
                  style: AppTypography.title.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${leadingChannel.label} es tu canal principal',
                  style: AppTypography.bodySm,
                ),
              ],
            ),
          ),
        ],
      );
}

class _ChannelBarChart extends StatelessWidget {
  const _ChannelBarChart({required this.channels});

  final List<ContactChannelDatum> channels;

  @override
  Widget build(BuildContext context) {
    final largestValue = channels.fold<int>(
      0,
      (largest, channel) => math.max(largest, channel.value),
    );
    final maxY = math.max(2.0, largestValue * 1.32);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: [
          for (var index = 0; index < channels.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: channels[index].value.toDouble(),
                  width: 24,
                  color: channels[index].color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusSm),
                  ),
                  label: BarChartRodLabel(
                    show: channels[index].value > 0,
                    text: '${channels[index].value}',
                    offset: const Offset(0, -8),
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= channels.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: AppSpacing.sm,
                  child: AppLineIcon(
                    channels[index].icon,
                    size: AppIconSize.inline,
                    color: channels[index].color,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            tooltipMargin: AppSpacing.sm,
            tooltipBorderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            getTooltipColor: (_) => AppColors.textPrimary,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final channel = channels[group.x];
              return BarTooltipItem(
                '${channel.label}\n',
                AppTypography.meta.copyWith(color: Colors.white),
                children: [
                  TextSpan(
                    text:
                        '${channel.value} ${channel.value == 1 ? 'contacto' : 'contactos'}',
                    style: AppTypography.label.copyWith(color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      duration:
          reducedMotion ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ChannelLegend extends StatelessWidget {
  const _ChannelLegend({
    required this.channels,
    required this.itemWidth,
  });

  final List<ContactChannelDatum> channels;
  final double itemWidth;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final channel in channels)
            SizedBox(
              width: itemWidth,
              child: Row(
                children: [
                  AppLineIcon(
                    channel.icon,
                    size: AppIconSize.inline,
                    color: channel.color,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      channel.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.meta,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${channel.value}',
                    style: AppTypography.label.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}

class _ZeroContactsState extends StatelessWidget {
  const _ZeroContactsState({required this.channels});

  final List<ContactChannelDatum> channels;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Aún no hay contactos en el período seleccionado.',
        child: ExcludeSemantics(
          child: Column(
            key: const Key('contact-channels-zero-state'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLineIcon(
                AppIcons.contacts,
                size: AppIconSize.feature,
                color: AppColors.celesteInk,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Aún no hay contactos', style: AppTypography.title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Cuando alguien te escriba o llame, verás aquí qué canal genera más conversaciones.',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final channel in channels)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppLineIcon(
                          channel.icon,
                          size: AppIconSize.inline,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(channel.label, style: AppTypography.meta),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppLineIcon(
            AppIcons.info,
            size: AppIconSize.leading,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Los canales de contacto aparecerán cuando recibas clics.',
              style: AppTypography.bodySm,
            ),
          ),
        ],
      );
}
