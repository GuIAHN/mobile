import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Indicador de puntos interactivo y animado para el onboarding.
/// El punto activo se muestra como una barra naranja,
/// los inactivos como círculos blancos semitransparentes.
class OnboardingDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const OnboardingDots({
    super.key,
    required this.count,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(i) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.white38,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
        );
      }),
    );
  }
}

