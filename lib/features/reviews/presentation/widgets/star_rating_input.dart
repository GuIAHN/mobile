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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (readOnly) {
      return Semantics(
        label: '$rating de 5 estrellas',
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                final isActive = index < rating;
                return SizedBox.square(
                  dimension: size + 4,
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isActive ? AppColors.primary : AppColors.grey400,
                    size: size,
                  ),
                );
              }),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isActive = starValue <= rating;

        return Semantics(
          button: true,
          selected: isActive,
          label: '$starValue ${starValue == 1 ? 'estrella' : 'estrellas'}',
          hint: 'Toca para seleccionar esta puntuación',
          child: InkResponse(
            onTap: () => onChanged?.call(starValue),
            radius: 24,
            child: SizedBox.square(
              dimension: 48,
              child: Center(
                child: AnimatedScale(
                  scale: isActive ? 1.08 : 1.0,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isActive ? AppColors.primary : AppColors.grey400,
                    size: size,
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
