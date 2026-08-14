import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final maxCount =
        steps.fold<int>(0, (max, s) => s.count > max ? s.count : max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
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
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: step.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: step.color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                step.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${step.count}',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTokens.textPrimary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Barra de progreso
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: step.color.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          step.color,
                          step.color.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
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
