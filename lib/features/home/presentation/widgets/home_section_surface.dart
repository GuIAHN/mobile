import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Separates featured home content from the neutral page canvas.
class HomeSectionSurface extends StatelessWidget {
  const HomeSectionSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        color: AppColors.surface,
        foregroundDecoration: const BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.border),
          ),
        ),
        child: child,
      );
}
