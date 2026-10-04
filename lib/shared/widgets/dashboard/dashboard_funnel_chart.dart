import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'dashboard_radial_chart.dart';

class DashboardFunnelStep {
  const DashboardFunnelStep({
    required this.name,
    required this.count,
    required this.color,
  });

  final String name;
  final int count;
  final Color color;
}

class DashboardFunnelChart extends StatelessWidget {
  const DashboardFunnelChart({
    super.key,
    required this.steps,
    this.emptyMessage = 'Aún no hay movimientos en el flujo para este período.',
  });

  final List<DashboardFunnelStep> steps;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return _FunnelSurface(child: _EmptyFunnel(message: emptyMessage));
    }

    final firstCount = steps.first.count;
    final finalCount = steps.last.count;
    final conversion = firstCount <= 0 ? 0.0 : finalCount / firstCount;
    final conversionPercentage = (conversion * 100).round();
    final stageSummary = [
      for (var index = 0; index < steps.length; index++)
        'Etapa ${index + 1}, ${steps[index].name}, ${steps[index].count}',
    ].join('. ');

    return Semantics(
      container: true,
      label:
          'Conversión total, $conversionPercentage por ciento. $stageSummary.',
      child: ExcludeSemantics(
        child: _FunnelSurface(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final useVerticalReadings = steps.length > 3 ||
                  constraints.maxWidth < 300 ||
                  textScale > 1.3;

              return Column(
                children: [
                  DashboardRadialChart(
                    key: const Key('dashboard-conversion-gauge'),
                    size: 172,
                    strokeWidth: 16,
                    startAngleDegrees: 145,
                    sweepAngleDegrees: 250,
                    tickCount: 11,
                    maxValue: firstCount <= 0 ? 1 : firstCount.toDouble(),
                    segments: [
                      DashboardRadialSegment(
                        value: finalCount.toDouble(),
                        color: steps.last.color,
                      ),
                    ],
                    semanticLabel:
                        'Medidor de conversión: $conversionPercentage por ciento',
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$conversionPercentage%',
                          maxLines: 1,
                          style: AppTypography.display.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'CONVERSIÓN',
                          textAlign: TextAlign.center,
                          style: AppTypography.overline.copyWith(
                            color: AppColors.textMeta,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$finalCount de $firstCount llegaron a la etapa final',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (useVerticalReadings)
                    _VerticalStageReadings(steps: steps)
                  else
                    _HorizontalStageReadings(steps: steps),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FunnelSurface extends StatelessWidget {
  const _FunnelSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _HorizontalStageReadings extends StatelessWidget {
  const _HorizontalStageReadings({required this.steps});

  final List<DashboardFunnelStep> steps;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(
              child: _StageReading(
                index: index,
                step: steps[index],
                previousCount: index == 0 ? null : steps[index - 1].count,
              ),
            ),
            if (index != steps.length - 1)
              const VerticalDivider(
                width: AppSpacing.xl,
                thickness: 1,
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _StageReading extends StatelessWidget {
  const _StageReading({
    required this.index,
    required this.step,
    required this.previousCount,
  });

  final int index;
  final DashboardFunnelStep step;
  final int? previousCount;

  @override
  Widget build(BuildContext context) {
    final retention = previousCount == null
        ? null
        : previousCount == 0
            ? 0
            : ((step.count / previousCount!) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${index + 1}'.padLeft(2, '0'),
              style: AppTypography.overline.copyWith(color: step.color),
            ),
            const Spacer(),
            Text(
              '${step.count}',
              style: AppTypography.display.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          step.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.label,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          retention == null ? 'Inicio' : '$retention% retención',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.meta.copyWith(color: AppColors.textMeta),
        ),
      ],
    );
  }
}

class _VerticalStageReadings extends StatelessWidget {
  const _VerticalStageReadings({required this.steps});

  final List<DashboardFunnelStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.lg),
          _VerticalStageReading(
            index: index,
            step: steps[index],
            previousCount: index == 0 ? null : steps[index - 1].count,
          ),
        ],
      ],
    );
  }
}

class _VerticalStageReading extends StatelessWidget {
  const _VerticalStageReading({
    required this.index,
    required this.step,
    required this.previousCount,
  });

  final int index;
  final DashboardFunnelStep step;
  final int? previousCount;

  @override
  Widget build(BuildContext context) {
    final retention = previousCount == null
        ? null
        : previousCount == 0
            ? 0
            : ((step.count / previousCount!) * 100).round();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSpacing.xl2,
          child: Text(
            '${index + 1}'.padLeft(2, '0'),
            style: AppTypography.overline.copyWith(color: step.color),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.name, style: AppTypography.label),
              const SizedBox(height: AppSpacing.xs),
              Text(
                retention == null
                    ? 'Inicio del flujo'
                    : '$retention% retención',
                style: AppTypography.meta.copyWith(color: AppColors.textMeta),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          '${step.count}',
          style: AppTypography.title.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _EmptyFunnel extends StatelessWidget {
  const _EmptyFunnel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: message,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLineIcon(
              AppIcons.dashboard,
              size: AppIconSize.leading,
              color: AppColors.textMeta,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message, style: AppTypography.bodySm)),
          ],
        ),
      ),
    );
  }
}
