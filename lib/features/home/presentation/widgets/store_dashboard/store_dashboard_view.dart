import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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

        Color stepColor = const Color(0xFF3A86FF); // Enviadas (Azul)
        if (key == 'BOUGHT') stepColor = const Color(0xFFF25C05); // Compradas (Naranja)
        if (key == 'DELIVERED') stepColor = const Color(0xFF10B981); // Entregadas (Verde)
        if (key == 'DISCARDED') stepColor = const Color(0xFF9CA3AF); // Descartadas (Gris)

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
                    colorFilter: const ColorFilter.mode(Color(0xFF059669), BlendMode.srcIn),
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
                    colorFilter: const ColorFilter.mode(Color(0xFF7C3AED), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFF7C3AED),
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF5F3FF),
                  deltaPct: opportunitiesMetric.payload['deltaPct'] != null
                      ? (opportunitiesMetric.payload['deltaPct'] as num).toDouble()
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
                    colorFilter: const ColorFilter.mode(Color(0xFFEA580C), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFFEA580C),
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFF7ED),
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
                    colorFilter: const ColorFilter.mode(Color(0xFF0D9488), BlendMode.srcIn),
                  ),
                  themeColor: const Color(0xFF0D9488),
                  iconColor: const Color(0xFF0D9488),
                  iconBgColor: const Color(0xFFF0FDFA),
                  deltaPct: conversionMetric.payload['deltaPct'] != null
                      ? (conversionMetric.payload['deltaPct'] as num).toDouble()
                      : null,
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
              Text(
                'Seleccionar Período',
                style: GoogleFonts.hankenGrotesk(
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
        style: GoogleFonts.hankenGrotesk(
          color: isSelected ? AppTokens.accent : AppTokens.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTokens.accent) : null,
    );
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

// Lucide SVG Icons constants
const _svgDollarSign = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="12" y1="1" x2="12" y2="23"></line>
  <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
</svg>''';

const _svgTarget = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <circle cx="12" cy="12" r="10"></circle>
  <circle cx="12" cy="12" r="6"></circle>
  <circle cx="12" cy="12" r="2"></circle>
</svg>''';

const _svgSend = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="22" y1="2" x2="11" y2="13"></line>
  <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
</svg>''';

const _svgTrendingUp = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"></polyline>
  <polyline points="17 6 23 6 23 12"></polyline>
</svg>''';
