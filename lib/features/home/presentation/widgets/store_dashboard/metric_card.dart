import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme/app_colors.dart';
import 'app_tokens.dart';

class MetricCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final String value;
  final double? deltaPct;
  final Color themeColor;
  final Color iconColor;
  final Color iconBgColor;
  final String? helperText;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.themeColor,
    required this.iconColor,
    required this.iconBgColor,
    this.deltaPct,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final hasDelta = deltaPct != null;
    final deltaVal = deltaPct ?? 0.0;
    final isPositive = deltaVal > 0;

    // Detectar si el valor de la métrica es cero
    final cleanVal = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final doubleVal = double.tryParse(cleanVal) ?? 0.0;
    final isZero = doubleVal == 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTokens.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label con ícono badge
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Valor principal
          Text(
            value,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppTokens.textPrimary,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          // Contexto / Tendencia Badge
          if (hasDelta && deltaVal != 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isPositive ? AppColors.successLight : AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 11,
                    color:
                        isPositive ? AppColors.successInk : AppColors.errorInk,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${isPositive ? '+' : ''}${deltaVal.toStringAsFixed(1)}%',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? AppColors.successInk
                          : AppColors.errorInk,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              deltaVal == 0 && hasDelta
                  ? 'Sin cambios'
                  : helperText ??
                      (isZero ? 'Sin datos este período' : 'Sin datos previos'),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppTokens.textTertiary,
              ),
            ),
        ],
      ),
    );
  }
}
