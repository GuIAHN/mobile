import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;
  final bool readOnly;

  const StarRatingInput({
    super.key,
    required this.rating,
    this.onChanged,
    this.size = 32.0,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = starValue <= rating;

        return GestureDetector(
          onTap: readOnly ? null : () => onChanged?.call(starValue),
          behavior: HitTestBehavior.opaque,
          child: AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isActive ? AppColors.primary : AppColors.border,
                size: size,
              ),
            ),
          ),
        );
      }),
    );
  }
}
