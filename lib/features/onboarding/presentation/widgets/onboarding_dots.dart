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
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return Semantics(
          label: 'Página ${i + 1} de $count',
          button: onTap != null,
          selected: isActive,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap != null ? () => onTap!(i) : null,
            child: SizedBox.square(
              key: Key('onboarding-dot-$i'),
              dimension: 48,
              child: Center(
                child: AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.white38,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
