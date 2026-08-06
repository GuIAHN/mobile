import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_tokens.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String context_;      // ej. "Sin datos este período"
  final bool isPositive;      // true → contexto en verde (ej. "↑ 12%")

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.context_ = 'Sin datos este período',
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTokens.cardPadding,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label con ícono
          Row(
            children: [
              Icon(icon, size: 15, color: AppTokens.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Valor principal
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimary,
              letterSpacing: -0.7,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          // Contexto
          Text(
            context_,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isPositive ? FontWeight.w500 : FontWeight.w400,
              color: isPositive ? AppTokens.green : AppTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
