import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/app_icons.dart';
import '../../../../../../core/theme/app_spacing.dart';
import '../../../../../../core/theme/app_typography.dart';
import '../../../../../../shared/widgets/dashboard/dashboard.dart';
import '../../../../../../shared/widgets/empty_state.dart';
import '../../../../../../shared/widgets/skeleton_loader.dart';
import '../../../../reports/domain/entities/store_dashboard.dart';
import '../../../../reports/presentation/providers/reports_provider.dart';
import 'contact_channels_chart.dart';

class ProviderDashboardView extends ConsumerWidget {
  const ProviderDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(providerDashboardProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: dashboardAsync.when(
        data: (dashboard) => dashboard.groups.isEmpty
            ? const _ProviderDashboardEmptyState()
            : _ProviderDashboardData(dashboard: dashboard),
        loading: () => const _ProviderDashboardLoading(),
        error: (_, __) => _ProviderDashboardError(
          onRetry: () => ref.invalidate(providerDashboardProvider),
        ),
      ),
    );
  }
}

class _ProviderDashboardData extends ConsumerWidget {
  const _ProviderDashboardData({required this.dashboard});

  final DashboardResponse dashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = _ProviderProfileSummary.fromDashboard(dashboard);
    final contacts = _contactTotal(dashboard.metricById('M-M04'));
    final reviewRate = _numberValue(dashboard.metricById('KPI-M02'));
    final rating = _ratingMedian(dashboard.metricById('M-M05'));
    final nps = _numberValue(dashboard.metricById('KPI-M03'));
    final channels = _contactChannels(dashboard.metricById('M-M06'));
    final funnel = _contactFunnel(dashboard.metricById('M-M07'));
    final currentDays = ref.watch(dashboardFilterProvider.notifier).currentDays;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileSummaryCard(summary: profile),
        const SizedBox(height: AppSpacing.xl),
        DashboardSectionHeader(
          title: 'Resumen de rendimiento',
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
        DashboardMetricGrid(
          baseItemExtent: 142,
          scaledItemGrowth: 200,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          children: [
            DashboardMetricCard(
              icon: AppIcons.contacts,
              label: 'Contactos',
              value: contacts?.toString() ?? '—',
              accentColor: AppColors.celesteInk,
              helperText: contacts == null
                  ? 'Dato no disponible'
                  : 'En el período seleccionado',
            ),
            DashboardMetricCard(
              icon: AppIcons.reviews,
              label: 'Reseñas por contacto',
              value: reviewRate == null ? '—' : '${_compact(reviewRate)}%',
              accentColor: AppColors.primary,
              helperText: reviewRate == null
                  ? 'Dato no disponible'
                  : 'De contactos a reseñas',
            ),
            DashboardMetricCard(
              icon: AppIcons.rating,
              label: 'Calificación',
              value: rating?.toStringAsFixed(1) ?? '—',
              accentColor: AppColors.warningInk,
              helperText:
                  rating == null ? 'Sin reseñas todavía' : 'Mediana de reseñas',
            ),
            DashboardMetricCard(
              icon: AppIcons.satisfaction,
              label: 'NPS',
              value: nps == null ? '—' : _compact(nps),
              accentColor: AppColors.successInk,
              helperText:
                  nps == null ? 'Dato no disponible' : 'Reputación estimada',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const DashboardSectionHeader(title: 'Cómo te contactan'),
        const SizedBox(height: AppSpacing.md),
        ContactChannelsChart(channels: channels),
        const SizedBox(height: AppSpacing.xl),
        const DashboardSectionHeader(title: 'De contacto a reseña'),
        const SizedBox(height: AppSpacing.md),
        if (funnel.isEmpty)
          const _InlineEmptyCard(
            message: 'Aún no hay interacciones para mostrar esta conversión.',
          )
        else
          DashboardFunnelChart(steps: funnel),
        const SizedBox(height: AppSpacing.xl3),
      ],
    );
  }
}

class _ProviderProfileSummary {
  const _ProviderProfileSummary({
    required this.verification,
    required this.serviceType,
    required this.specialtyCount,
  });

  final String? verification;
  final String? serviceType;
  final int? specialtyCount;

  factory _ProviderProfileSummary.fromDashboard(
    DashboardResponse dashboard,
  ) {
    return _ProviderProfileSummary(
      verification: _firstRowValue(
        dashboard.metricById('M-M02'),
        'verified',
      ),
      serviceType: _firstRowValue(
        dashboard.metricById('M-M03'),
        'type',
      ),
      specialtyCount: _listPayload(
        dashboard.metricById('M-M01'),
        'axes',
      )?.length,
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.summary});

  final _ProviderProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    final isVerified = summary.verification?.toLowerCase() == 'verificado';
    final statusLabel = summary.verification == null
        ? 'Estado del perfil no disponible'
        : isVerified
            ? 'Perfil verificado'
            : 'Verificación pendiente';
    final specialtyLabel = summary.specialtyCount == null
        ? 'Especialidades no disponibles'
        : summary.specialtyCount == 1
            ? '1 especialidad activa'
            : '${summary.specialtyCount} especialidades activas';

    return Semantics(
      container: true,
      label: '$statusLabel. ${summary.serviceType ?? ''}. $specialtyLabel',
      child: Container(
        key: const Key('provider-profile-summary'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
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
            AppLineIcon(
              isVerified ? AppIcons.verified : AppIcons.info,
              size: AppIconSize.leading,
              color: isVerified ? AppColors.successInk : AppColors.primaryInk,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabel, style: AppTypography.title),
                  if (summary.serviceType != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(summary.serviceType!, style: AppTypography.bodySm),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(specialtyLabel, style: AppTypography.meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineEmptyCard extends StatelessWidget {
  const _InlineEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(message, style: AppTypography.bodySm),
      );
}

class _ProviderDashboardLoading extends StatelessWidget {
  const _ProviderDashboardLoading();

  @override
  Widget build(BuildContext context) => const Column(
        key: Key('provider-dashboard-skeleton'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            height: 112,
            width: double.infinity,
            borderRadius: AppSpacing.radiusXl,
          ),
          SizedBox(height: AppSpacing.xl),
          SkeletonBox(height: 28, width: 220),
          SizedBox(height: AppSpacing.md),
          DashboardMetricSkeletonGrid(
            itemCount: 4,
            keyPrefix: 'provider-kpi-skeleton',
            itemExtent: 140,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      );
}

class _ProviderDashboardError extends StatelessWidget {
  const _ProviderDashboardError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl3),
        child: EmptyState(
          title: 'No pudimos cargar tus estadísticas',
          subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          icon: AppIcons.dashboard,
          action: ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 48),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ),
      );
}

class _ProviderDashboardEmptyState extends StatelessWidget {
  const _ProviderDashboardEmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl3),
        child: EmptyState(
          title: 'Aún no hay estadísticas disponibles',
          subtitle:
              'Tu actividad aparecerá aquí a medida que recibas contactos.',
          icon: AppIcons.dashboard,
        ),
      );
}

List<dynamic>? _listPayload(MetricResult? metric, String key) {
  if (metric == null || metric.availability == 'BLOCKED') return null;
  final value = metric.payload[key];
  return value is List<dynamic> ? value : null;
}

Map<String, dynamic>? _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String? _firstRowValue(MetricResult? metric, String key) {
  final rows = _listPayload(metric, 'rows');
  if (rows == null || rows.isEmpty) return null;
  return _asMap(rows.first)?[key]?.toString();
}

num? _numberValue(MetricResult? metric) {
  if (metric == null || metric.availability == 'BLOCKED') return null;
  final value = metric.payload['value'];
  return value is num ? value : num.tryParse(value?.toString() ?? '');
}

int? _contactTotal(MetricResult? metric) {
  final series = _listPayload(metric, 'series');
  if (series == null) return null;
  var total = 0;
  for (final rawSeries in series) {
    final points = _asMap(rawSeries)?['points'];
    if (points is! List) continue;
    for (final point in points) {
      final value = _asMap(point)?['y'];
      if (value is num) total += value.toInt();
    }
  }
  return total;
}

double? _ratingMedian(MetricResult? metric) {
  if (metric == null || metric.availability == 'BLOCKED') return null;
  final median = metric.payload['median'];
  return median is num ? median.toDouble() : null;
}

List<ContactChannelDatum> _contactChannels(MetricResult? metric) {
  final slices = _listPayload(metric, 'slices');
  if (slices == null) return const [];

  final values = <String, int>{
    'PHONE': 0,
    'WHATSAPP': 0,
    'INSTAGRAM': 0,
    'OTHER': 0,
  };
  for (final slice in slices) {
    final map = _asMap(slice) ?? const <String, dynamic>{};
    final key = map['x']?.toString().toUpperCase() ?? 'OTHER';
    final normalizedKey = values.containsKey(key) ? key : 'OTHER';
    values[normalizedKey] =
        values[normalizedKey]! + ((map['y'] as num?)?.toInt() ?? 0);
  }

  return [
    ContactChannelDatum(
      label: 'Teléfono',
      value: values['PHONE']!,
      icon: AppIcons.call,
      color: AppColors.celesteInk,
    ),
    ContactChannelDatum(
      label: 'WhatsApp',
      value: values['WHATSAPP']!,
      icon: AppIcons.message,
      color: AppColors.successInk,
    ),
    ContactChannelDatum(
      label: 'Instagram',
      value: values['INSTAGRAM']!,
      icon: AppIcons.socialContact,
      color: AppColors.primary,
    ),
    ContactChannelDatum(
      label: 'Otros',
      value: values['OTHER']!,
      icon: AppIcons.otherContact,
      color: AppColors.textSecondary,
    ),
  ];
}

List<DashboardFunnelStep> _contactFunnel(MetricResult? metric) {
  final stages = _listPayload(metric, 'stages');
  if (stages == null) return const [];
  return stages.map((stage) {
    final map = _asMap(stage) ?? const <String, dynamic>{};
    final isReview = map['key'] == 'REVIEW';
    return DashboardFunnelStep(
      name: map['label']?.toString() ?? '',
      count: (map['value'] as num?)?.toInt() ?? 0,
      color: isReview ? AppColors.success : AppColors.primary,
    );
  }).toList();
}

String _compact(num value) {
  final asDouble = value.toDouble();
  return asDouble == asDouble.roundToDouble()
      ? asDouble.toInt().toString()
      : asDouble.toStringAsFixed(1);
}
