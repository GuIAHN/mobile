import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../shared/widgets/empty_state.dart';
import '../../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../reports/presentation/providers/reports_provider.dart';
import '../../../../reports/domain/entities/store_dashboard.dart';
import 'metric_card.dart';
import 'store_funnel_chart.dart';
import 'section_header.dart';
import 'app_tokens.dart';

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
        error: (err, stack) => _buildErrorState(err.toString(), ref),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, DashboardResponse dashboard) {
    // Helper to find metric by id across all groups
    MetricResult? findMetric(String id) {
      for (final group in dashboard.groups) {
        for (final panel in group.panels) {
          if (panel.id == id && panel.metric != null) {
            return panel.metric;
          }
        }
      }
      return null;
    }

    final salesMetric = findMetric('M-T06'); // Ventas Brutas
    final opportunitiesMetric = findMetric('M-T01'); // Oportunidades
    final quotesMetric = findMetric('M-T02') ?? findMetric('M-T07'); // Cotizaciones emitidas / unidades
    final conversionMetric = findMetric('KPI-T02'); // Tasa de conversion
    final funnelMetric = findMetric('M-T03'); // Embudo de ofertas

    List<FunnelStep> funnelSteps = [];
    if (funnelMetric != null) {
      final stagesRaw = funnelMetric.payload['stages'] as List<dynamic>? ?? [];
      final stages = stagesRaw.cast<Map<String, dynamic>>();
      for (var stage in stages) {
        final value = (stage['value'] as num).toDouble();
        final label = stage['label'] as String? ?? '';
        final key = stage['key'] as String? ?? '';

        Color stepColor = AppTokens.funnelStep1;
        if (key == 'BOUGHT') stepColor = AppTokens.funnelStep2;
        if (key == 'DELIVERED') stepColor = AppTokens.funnelStep3;
        if (key == 'DISCARDED') stepColor = AppTokens.textTertiary;

        funnelSteps.add(FunnelStep(name: label, count: value.toInt(), color: stepColor));
      }
    }

    final currentDays = ref.watch(storeDashboardFilterProvider.notifier).currentDays;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Resumen de Actividad',
            trailing: PeriodSelector(
              label: '$currentDays días',
              onTap: () {
                _showPeriodBottomSheet(context, ref, currentDays);
              },
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              if (salesMetric != null)
                MetricCard(
                  label: 'Ventas',
                  value: 'L ${salesMetric.payload['value'] ?? '0.00'}',
                  icon: Icons.attach_money,
                  context_: _formatContext(salesMetric.payload['deltaPct']),
                  isPositive: _isPositiveDelta(salesMetric.payload['deltaPct']),
                ),
              if (opportunitiesMetric != null)
                MetricCard(
                  label: 'Oportunidades',
                  value: '${opportunitiesMetric.payload['value'] ?? 0}',
                  icon: Icons.track_changes,
                  context_: _formatContext(opportunitiesMetric.payload['deltaPct']),
                  isPositive: _isPositiveDelta(opportunitiesMetric.payload['deltaPct']),
                ),
              if (quotesMetric != null)
                MetricCard(
                  label: 'Cotizaciones',
                  value: '${quotesMetric.payload['value'] ?? 0}',
                  icon: Icons.send_outlined,
                  context_: _formatContext(quotesMetric.payload['deltaPct']),
                  isPositive: _isPositiveDelta(quotesMetric.payload['deltaPct']),
                ),
              if (conversionMetric != null)
                MetricCard(
                  label: 'Conversión',
                  value: '${conversionMetric.payload['value'] ?? 0}%',
                  icon: Icons.trending_up,
                  context_: _formatContext(conversionMetric.payload['deltaPct']),
                  isPositive: _isPositiveDelta(conversionMetric.payload['deltaPct']),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Flujo de Ventas'),
          const SizedBox(height: 12),
          if (funnelSteps.isNotEmpty)
            StoreFunnelChart(steps: funnelSteps),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPeriodBottomSheet(BuildContext context, WidgetRef ref, int currentDays) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seleccionar Período',
                style: TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildOption(ctx, ref, 7, currentDays),
              _buildOption(ctx, ref, 15, currentDays),
              _buildOption(ctx, ref, 30, currentDays),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, int days, int currentDays) {
    final isSelected = days == currentDays;
    return ListTile(
      onTap: () {
        ref.read(storeDashboardFilterProvider.notifier).updateDays(days);
        Navigator.pop(context);
      },
      title: Text(
        'Últimos $days días',
        style: TextStyle(
          color: isSelected ? AppTokens.accent : AppTokens.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTokens.accent) : null,
    );
  }

  String _formatContext(dynamic delta) {
    if (delta == null) return 'Sin datos este período';
    final value = (delta as num).toDouble();
    if (value > 0) return '↑ +${value.toStringAsFixed(1)}%';
    if (value < 0) return '↓ ${value.toStringAsFixed(1)}%';
    return 'Sin cambios';
  }

  bool _isPositiveDelta(dynamic delta) {
    if (delta == null) return false;
    final value = (delta as num).toDouble();
    return value > 0;
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: List.generate(4, (_) => const SkeletonBox(height: 120, width: double.infinity, borderRadius: 20)),
        ),
        const SizedBox(height: 24),
        const SkeletonBox(height: 24, width: 180),
        const SizedBox(height: 16),
        const SkeletonBox(height: 200, width: double.infinity, borderRadius: 20),
      ],
    );
  }

  Widget _buildErrorState(String error, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: EmptyState(
        title: 'Error al cargar dashboard',
        subtitle: error,
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
