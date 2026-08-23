import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/empty_state.dart';
import '../../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../reports/presentation/providers/reports_provider.dart';
import '../../../../reports/domain/entities/store_dashboard.dart';
import 'metric_card.dart';
import 'store_funnel_chart.dart';
import 'section_header.dart';
import 'billing_balance_card.dart';

class StoreDashboardView extends ConsumerWidget {
  const StoreDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(storeDashboardProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: dashboardAsync.when(
        data: (dashboard) => _buildDashboard(context, ref, dashboard),
        loading: () => _buildLoadingState(),
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

    List<FunnelStep> funnelSteps = [];
    if (funnelMetric != null) {
      final stagesRaw = funnelMetric.payload['stages'] as List<dynamic>? ?? [];
      final stages = stagesRaw.cast<Map<String, dynamic>>();
      for (var stage in stages) {
        final value = (stage['value'] as num).toDouble();
        final label = stage['label'] as String? ?? '';
        final key = stage['key'] as String? ?? '';

        Color stepColor = const Color(0xFF3A86FF); // Enviadas (Azul)
        if (key == 'BOUGHT') {
          stepColor = const Color(0xFFF25C05); // Compradas (Naranja)
        }
        if (key == 'DELIVERED') {
          stepColor = const Color(0xFF10B981); // Entregadas (Verde)
        }
        if (key == 'DISCARDED') {
          stepColor = const Color(0xFF9CA3AF); // Descartadas (Gris)
        }

        funnelSteps.add(
            FunnelStep(name: label, count: value.toInt(), color: stepColor));
      }
    }

    final currentDays =
        ref.watch(storeDashboardFilterProvider.notifier).currentDays;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BillingBalanceCard(amount: outstandingBalance),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Resumen de Actividad',
            trailing: PeriodSelector(
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
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              if (salesMetric != null)
                MetricCard(
                  label: 'Ventas',
                  value: '\$ ${salesMetric.payload['value'] ?? '0.00'}',
                  icon: SvgPicture.string(
                    _svgDollarSign,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF059669), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFF059669),
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFECFDF5),
                  deltaPct: salesMetric.payload['deltaPct'] != null
                      ? (salesMetric.payload['deltaPct'] as num).toDouble()
                      : null,
                ),
              if (opportunitiesMetric != null)
                MetricCard(
                  label: 'Oportunidades',
                  value: '${opportunitiesMetric.payload['value'] ?? 0}',
                  icon: SvgPicture.string(
                    _svgTarget,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF7C3AED), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFF7C3AED),
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  deltaPct: opportunitiesMetric.payload['deltaPct'] != null
                      ? (opportunitiesMetric.payload['deltaPct'] as num)
                          .toDouble()
                      : null,
                ),
              if (quotesMetric != null)
                MetricCard(
                  label: 'Cotizaciones',
                  value: '${quotesMetric.payload['value'] ?? 0}',
                  icon: SvgPicture.string(
                    _svgSend,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        AppColors.primary, BlendMode.srcIn),
                  ),
                  themeColor: AppColors.primary,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryMuted,
                  deltaPct: quotesMetric.payload['deltaPct'] != null
                      ? (quotesMetric.payload['deltaPct'] as num).toDouble()
                      : null,
                ),
              if (conversionMetric != null)
                MetricCard(
                  label: 'Conversión',
                  value: '${conversionMetric.payload['value'] ?? 0}%',
                  icon: SvgPicture.string(
                    _svgTrendingUp,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF0D9488), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFF0D9488),
                  iconColor: const Color(0xFF0D9488),
                  iconBgColor: const Color(0xFFF0FDFA),
                  deltaPct: conversionMetric.payload['deltaPct'] != null
                      ? (conversionMetric.payload['deltaPct'] as num).toDouble()
                      : null,
                ),
              if (cancellationMetric != null)
                MetricCard(
                  label: 'Cancelación',
                  value: _percentageValue(cancellationMetric),
                  icon: const Icon(
                    Icons.block_rounded,
                    size: 20,
                    color: AppColors.errorInk,
                  ),
                  themeColor: AppColors.error,
                  iconColor: AppColors.errorInk,
                  iconBgColor: AppColors.errorLight,
                ),
              if (declineMetric != null)
                MetricCard(
                  label: 'Declinadas',
                  value: _percentageValue(declineMetric),
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 20,
                    color: Color(0xFF7C3AED),
                  ),
                  themeColor: const Color(0xFF7C3AED),
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Flujo de Ventas'),
          const SizedBox(height: 12),
          if (funnelSteps.isNotEmpty) StoreFunnelChart(steps: funnelSteps),
          if (declineReasonsMetric != null) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Motivos de solicitudes declinadas'),
            const SizedBox(height: 12),
            _DeclineReasonsCard(metric: declineReasonsMetric),
          ],
          const SizedBox(height: 24),
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

  String _percentageValue(MetricResult metric) {
    final value = metric.payload['value'];
    if (value == null) return '—';
    if (value is num) return '${value.toStringAsFixed(1)}%';
    return '$value%';
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const SkeletonBox(
          key: Key('store-billing-balance-skeleton'),
          height: 136,
          width: double.infinity,
          borderRadius: 20,
        ),
        const SizedBox(height: 20),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: List.generate(
              4,
              (_) => const SkeletonBox(
                  height: 120, width: double.infinity, borderRadius: 20)),
        ),
        const SizedBox(height: 24),
        const SkeletonBox(height: 24, width: 180),
        const SizedBox(height: 16),
        const SkeletonBox(
            height: 200, width: double.infinity, borderRadius: 20),
      ],
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
        padding: const EdgeInsets.only(top: 32),
        child: EmptyState(
          title: 'Dashboard temporalmente bloqueado',
          subtitle: '${error.message}\n\n'
              'Mediana: $median min · Límite: $threshold min\n'
              'Muestra: $sample de $minSample respuestas requeridas',
          icon: Icons.speed_rounded,
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
            icon: const Icon(Icons.refresh_rounded),
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
      padding: const EdgeInsets.only(top: 32.0),
      child: EmptyState(
        title: 'Error al cargar dashboard',
        subtitle: error.toString(),
        icon: Icons.error_outline_rounded,
        action: ElevatedButton(
          onPressed: () => ref.invalidate(storeDashboardProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reintentar'),
        ),
      ),
    );
  }
}

class _DeclineReasonsCard extends StatelessWidget {
  final MetricResult metric;

  const _DeclineReasonsCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final rawSlices = metric.payload['slices'] as List<dynamic>? ?? const [];
    final slices = rawSlices.whereType<Map<String, dynamic>>().toList();
    final rawTotal = metric.payload['total'];
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : slices.fold<double>(
            0,
            (sum, item) => sum + ((item['y'] as num?)?.toDouble() ?? 0),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: slices.isEmpty
          ? const Text(
              'Aún no hay solicitudes declinadas en este período.',
              style: TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (var index = 0; index < slices.length; index++) ...[
                  _DeclineReasonRow(
                    label: slices[index]['label'] as String? ??
                        slices[index]['x']?.toString() ??
                        'Otro',
                    count: (slices[index]['y'] as num?)?.toInt() ?? 0,
                    total: total,
                  ),
                  if (index != slices.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _DeclineReasonRow extends StatelessWidget {
  final String label;
  final int count;
  final double total;

  const _DeclineReasonRow({
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Semantics(
      label: '$label, $count, ${(ratio * 100).toStringAsFixed(0)} por ciento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 7,
              color: AppColors.primary,
              backgroundColor: AppColors.primaryMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// Lucide SVG Icons constants
const _svgDollarSign =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="12" y1="1" x2="12" y2="23"></line>
  <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
</svg>''';

const _svgTarget =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"></circle>
  <circle cx="12" cy="12" r="6"></circle>
  <circle cx="12" cy="12" r="2"></circle>
</svg>''';

const _svgSend =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="22" y1="2" x2="11" y2="13"></line>
  <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
</svg>''';

const _svgTrendingUp =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline>
  <polyline points="17 6 23 6 23 12"></polyline>
</svg>''';
