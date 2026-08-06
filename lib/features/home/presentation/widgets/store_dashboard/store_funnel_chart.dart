import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_tokens.dart';

class FunnelStep {
  final String name;
  final int count;
  final Color color;

  const FunnelStep({
    required this.name,
    required this.count,
    required this.color,
  });
}

class StoreFunnelChart extends StatelessWidget {
  final List<FunnelStep> steps;

  const StoreFunnelChart({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    // El máximo define el 100% de la barra
    final maxCount = steps.fold<int>(0, (max, s) => s.count > max ? s.count : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _FunnelRow(
              step: steps[i],
              fraction: maxCount == 0 ? 0 : steps[i].count / maxCount,
            ),
          ],
        ],
      ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  final FunnelStep step;
  final double fraction;

  const _FunnelRow({required this.step, required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              step.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondary,
              ),
            ),
            Text(
              '${step.count}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTokens.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: step.color.withValues(alpha: 0.15)),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: step.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
