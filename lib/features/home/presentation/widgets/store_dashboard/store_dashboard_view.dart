import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_decorations.dart';
import '../../../../../../core/theme/app_icons.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../shared/widgets/empty_state.dart';
import '../../../../../../shared/widgets/dashboard/dashboard.dart';
import '../../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../../../shared/widgets/staggered_entrance.dart';
import '../../../../reports/presentation/providers/reports_provider.dart';
import '../../../../reports/domain/entities/store_dashboard.dart';
import 'billing_balance_card.dart';

class StoreDashboardView extends ConsumerWidget {
  const StoreDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(storeDashboardProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      child: dashboardAsync.when(
        data: (dashboard) => _buildDashboard(context, ref, dashboard),
        loading: () => _buildLoadingState(context),
        error: (err, stack) => _buildErrorState(context, err, ref),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardResponse dashboard,
  ) {
    final salesMetric = dashboard.metricById('M-T06'); // Ventas Brutas
    final opportunitiesMetric = dashboard.metricById('M-T01');
    final quotesMetric =
        dashboard.metricById('M-T02') ?? dashboard.metricById('M-T07');
    final conversionMetric = dashboard.metricById('KPI-T02');
    final cancellationMetric = dashboard.metricById('KPI-T07');
    final declineMetric = dashboard.metricById('KPI-T08');
    final declineReasonsMetric = dashboard.metricById('M-T11');
    final funnelMetric = dashboard.metricById('M-T03');
    final outstandingBalanceMetric = dashboard.metricById('M-T10');
    final outstandingBalance = _metricValue(outstandingBalanceMetric);

    List<DashboardFunnelStep> funnelSteps = [];
    if (funnelMetric != null) {
      final stagesRaw = funnelMetric.payload['stages'] as List<dynamic>? ?? [];
      final stages = stagesRaw.cast<Map<String, dynamic>>();
      for (var stage in stages) {
        final value = (stage['value'] as num).toDouble();
        final label = stage['label'] as String? ?? '';
        final key = stage['key'] as String? ?? '';

        Color stepColor = AppColors.tertiary;
        if (key == 'BOUGHT') {
          stepColor = AppColors.primary;
        }
        if (key == 'DELIVERED') {
          stepColor = AppColors.successInk;
        }
        if (key == 'DISCARDED') {
          stepColor = AppColors.textMeta;
        }

        funnelSteps.add(
          DashboardFunnelStep(
            name: label,
            count: value.toInt(),
            color: stepColor,
          ),
        );
      }
    }

    final currentDays =
        ref.watch(storeDashboardFilterProvider.notifier).currentDays;

    final metrics = <Widget>[
      DashboardMetricCard(
        key: const Key('store-kpi-sales'),
        label: 'Ventas',
        value: _currencyDisplayValue(salesMetric),
        icon: AppIcons.sales,
        accentColor: AppColors.successInk,
        deltaPct: _deltaValue(salesMetric),
      ),
      DashboardMetricCard(
        key: const Key('store-kpi-opportunities'),
        label: 'Oportunidades',
        value: _displayValue(opportunitiesMetric),
        icon: AppIcons.opportunity,
        accentColor: AppColors.tertiary,
        deltaPct: _deltaValue(opportunitiesMetric),
      ),
      DashboardMetricCard(
        key: const Key('store-kpi-quotes'),
        label: 'Cotizaciones',
        value: _displayValue(quotesMetric),
        icon: AppIcons.send,
        accentColor: AppColors.primary,
        deltaPct: _deltaValue(quotesMetric),
      ),
      DashboardMetricCard(
        key: const Key('store-kpi-conversion'),
        label: 'Conversión',
        value: _percentageValue(conversionMetric),
        icon: AppIcons.conversion,
        accentColor: AppColors.celesteInk,
        deltaPct: _deltaValue(conversionMetric),
      ),
      DashboardMetricCard(
        key: const Key('store-kpi-cancellation'),
        label: 'Cancelación',
        value: _percentageValue(
          cancellationMetric,
          forceOneDecimal: true,
        ),
        icon: AppIcons.cancellation,
        accentColor: AppColors.errorInk,
      ),
      DashboardMetricCard(
        key: const Key('store-kpi-declined'),
        label: 'Declinadas',
        value: _percentageValue(
          declineMetric,
          forceOneDecimal: true,
        ),
        icon: AppIcons.declined,
        accentColor: AppColors.warningInk,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredEntrance(
            index: 0,
            child: BillingBalanceCard(amount: outstandingBalance),
          ),
          const SizedBox(height: AppSpacing.xl2),
          DashboardSectionHeader(
            title: 'Resumen de actividad',
            subtitle: '6 indicadores del período',
            trailing: DashboardPeriodSelector(
              label: '$currentDays días',
              onTap: () async {
                final days = await showDashboardPeriodBottomSheet(
                  context,
                  currentDays: currentDays,
                );
                if (days != null) {
                  ref.read(dashboardFilterProvider.notifier).updateDays(days);
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 1,
            child: DashboardMetricGrid(children: metrics),
          ),
          const SizedBox(height: AppSpacing.xl2),
          const DashboardSectionHeader(
            title: 'Flujo de ventas',
            subtitle: 'Avance por etapa del proceso',
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 2,
            child: DashboardFunnelChart(
              steps: funnelSteps,
              emptyMessage:
                  'Aún no hay movimientos en el flujo de ventas para este período.',
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          const DashboardSectionHeader(
            title: 'Motivos de solicitudes declinadas',
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredEntrance(
            index: 3,
            child: _DeclineReasonsCard(metric: declineReasonsMetric),
          ),
          const SizedBox(height: AppSpacing.xl3),
        ],
      ),
    );
  }

  double? _metricValue(MetricResult? metric) {
    if (metric == null || metric.availability != 'AVAILABLE') return null;

    final value = metric.payload['value'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _displayValue(MetricResult? metric) {
    if (!_hasDisplayValue(metric)) return '—';
    return '${metric!.payload['value']}';
  }

  String _currencyDisplayValue(MetricResult? metric) {
    final value = _displayValue(metric);
    return value == '—' ? value : '\$ $value';
  }

  String _percentageValue(
    MetricResult? metric, {
    bool forceOneDecimal = false,
  }) {
    if (!_hasDisplayValue(metric)) return '—';
    final value = metric!.payload['value'];
    if (value is num) {
      return forceOneDecimal ? '${value.toStringAsFixed(1)}%' : '$value%';
    }
    return '$value%';
  }

  bool _hasDisplayValue(MetricResult? metric) {
    return metric != null &&
        metric.availability != 'BLOCKED' &&
        metric.payload['value'] != null;
  }

  double? _deltaValue(MetricResult? metric) {
    if (metric == null || metric.availability == 'BLOCKED') return null;
    final delta = metric.payload['deltaPct'];
    return delta is num ? delta.toDouble() : null;
  }

  Widget _buildLoadingState(BuildContext context) {
    return TickerMode(
      enabled: !MediaQuery.disableAnimationsOf(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(
            key: Key('store-billing-balance-skeleton'),
            height: 184,
            width: double.infinity,
            borderRadius: AppSpacing.radiusXl,
          ),
          SizedBox(height: AppSpacing.xl2),
          SkeletonBox(height: 24, width: 208, borderRadius: 8),
          SizedBox(height: AppSpacing.md),
          DashboardMetricSkeletonGrid(
            itemCount: 6,
            keyPrefix: 'store-kpi-skeleton',
          ),
          SizedBox(height: AppSpacing.xl2),
          SkeletonBox(height: 24, width: 156, borderRadius: 8),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(
            height: 220,
            width: double.infinity,
            borderRadius: AppSpacing.radiusLg,
          ),
          SizedBox(height: AppSpacing.xl2),
          SkeletonBox(height: 24, width: 244, borderRadius: 8),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(
            height: 96,
            width: double.infinity,
            borderRadius: AppSpacing.radiusLg,
          ),
          SizedBox(height: AppSpacing.xl3),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    WidgetRef ref,
  ) {
    if (error is StoreMetricsBlockedException) {
      final status = error.status;
      final median = status.medianMinutes?.toStringAsFixed(0) ?? '—';
      final threshold = status.thresholdMinutes?.toStringAsFixed(0) ?? '—';
      final sample = status.sampleSize?.toStringAsFixed(0) ?? '—';
      final minSample = status.minSample?.toStringAsFixed(0) ?? '—';

      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xl3),
        child: EmptyState(
          title: 'Dashboard temporalmente bloqueado',
          subtitle: '${error.message}\n\n'
              'Mediana: $median min · Límite: $threshold min\n'
              'Muestra: $sample de $minSample respuestas requeridas',
          icon: AppIcons.dashboard,
          action: ElevatedButton.icon(
            onPressed: () async {
              try {
                final latest =
                    await ref.refresh(storeResponseStatusProvider.future);
                if (!context.mounted) return;
                if (latest.blocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'El acceso sigue bloqueado. Continúa respondiendo más rápido.',
                      ),
                    ),
                  );
                }
                ref.invalidate(storeDashboardProvider);
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se pudo actualizar el diagnóstico.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            icon: const AppLineIcon(
              AppIcons.retry,
              size: AppIconSize.action,
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            label: const Text('Comprobar de nuevo'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl3),
      child: EmptyState(
        title: 'Error al cargar dashboard',
        subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
        icon: AppIcons.connectivityError,
        action: ElevatedButton.icon(
          onPressed: () => ref.invalidate(storeDashboardProvider),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          icon: const AppLineIcon(
            AppIcons.retry,
            size: AppIconSize.action,
          ),
          label: const Text('Reintentar'),
        ),
      ),
    );
  }
}

class _DeclineReasonsCard extends StatelessWidget {
  const _DeclineReasonsCard({required this.metric});

  static const _chartColors = [
    AppColors.primary,
    AppColors.tertiary,
    AppColors.successInk,
    AppColors.warningInk,
    AppColors.celesteInk,
  ];

  final MetricResult? metric;

  @override
  Widget build(BuildContext context) {
    final rawSlices =
        metric?.payload['slices'] as List<dynamic>? ?? const <dynamic>[];
    final slices = rawSlices.whereType<Map<String, dynamic>>().toList();
    final rawTotal = metric?.payload['total'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : slices.fold<double>(
            0,
            (sum, item) => sum + ((item['y'] as num?)?.toDouble() ?? 0),
          );
    final reasons = [
      for (var index = 0; index < slices.length; index++)
        _DeclineReason(
          label: slices[index]['label'] as String? ??
              slices[index]['x']?.toString() ??
              'Otro',
          count: (slices[index]['y'] as num?)?.toInt() ?? 0,
          color: _chartColors[index % _chartColors.length],
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDecorations.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppDecorations.soft,
      ),
      child: reasons.isEmpty
          ? Semantics(
              container: true,
              label: metric == null
                  ? 'Los motivos de solicitudes declinadas no están disponibles'
                  : 'Aún no hay solicitudes declinadas en este período',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLineIcon(
                      AppIcons.declined,
                      size: AppIconSize.leading,
                      color: AppColors.textMeta,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        metric == null
                            ? 'Los motivos no están disponibles en este momento.'
                            : 'Aún no hay solicitudes declinadas en este período.',
                        style: AppTypography.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _DeclineReasonsVisualization(reasons: reasons, total: total),
    );
  }
}

class _DeclineReason {
  const _DeclineReason({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

class _DeclineReasonsVisualization extends StatelessWidget {
  const _DeclineReasonsVisualization({
    required this.reasons,
    required this.total,
  });

  final List<_DeclineReason> reasons;
  final double total;

  @override
  Widget build(BuildContext context) {
    final totalText = total == total.roundToDouble()
        ? total.toInt().toString()
        : total.toStringAsFixed(1);
    final summary = reasons
        .map(
          (reason) =>
              '${reason.label}, ${reason.count}, ${_percentage(reason.count, total)} por ciento',
        )
        .join('. ');

    return Semantics(
      container: true,
      label: '$totalText solicitudes declinadas. $summary.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final showDistributionChart = reasons.length <= 5;
            final stackContent = constraints.maxWidth < 270 || textScale > 1.3;
            final legend = _DeclineReasonsLegend(
              reasons: reasons,
              total: total,
            );

            if (!showDistributionChart) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    totalText,
                    style: AppTypography.display.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('SOLICITUDES DECLINADAS', style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.xl),
                  legend,
                ],
              );
            }

            final chart = DashboardRadialChart(
              key: const Key('decline-reasons-distribution-chart'),
              size: 128,
              strokeWidth: 14,
              maxValue: total <= 0 ? 1 : total,
              segments: [
                for (final reason in reasons)
                  DashboardRadialSegment(
                    value: reason.count.toDouble(),
                    color: reason.color,
                  ),
              ],
              semanticLabel: 'Distribución de motivos declinados. $summary',
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalText,
                    maxLines: 1,
                    style: AppTypography.display.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'DECLINADAS',
                    textAlign: TextAlign.center,
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textMeta,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );

            if (stackContent) {
              return Column(
                children: [
                  chart,
                  const SizedBox(height: AppSpacing.xl),
                  legend,
                ],
              );
            }

            return Row(
              children: [
                chart,
                const SizedBox(width: AppSpacing.xl),
                Expanded(child: legend),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _percentage(int count, double total) {
    return total <= 0 ? 0 : ((count / total) * 100).round();
  }
}

class _DeclineReasonsLegend extends StatelessWidget {
  const _DeclineReasonsLegend({
    required this.reasons,
    required this.total,
  });

  final List<_DeclineReason> reasons;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < reasons.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: reasons[index].color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reasons[index].label, style: AppTypography.label),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${_percentage(reasons[index].count)}% del total',
                      style: AppTypography.meta.copyWith(
                        color: AppColors.textMeta,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${reasons[index].count}',
                style: AppTypography.title.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  int _percentage(int count) {
    return total <= 0 ? 0 : ((count / total) * 100).round();
  }
}
