import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Acceso público a las reseñas recibidas por un mecánico o taller.
class ProviderReviewsButton extends StatelessWidget {
  final String targetId;
  final double? rating;
  final int reviewCount;

  const ProviderReviewsButton({
    super.key,
    required this.targetId,
    this.rating,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver reseñas de clientes',
      child: OutlinedButton(
        key: const Key('open-provider-reviews'),
        onPressed: () => context.push(
          RouteNames.providerReviewsPath(targetId),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeightLg),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          foregroundColor: AppColors.primaryInk,
          backgroundColor: AppColors.surface,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: AppSpacing.xl3,
              child: AppLineIcon(
                AppIcons.reviews,
                size: AppIconSize.leading,
                color: AppColors.primaryInk,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver reseñas de clientes',
                    style: AppTypography.title.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _supportingText,
                    style: AppTypography.meta.copyWith(
                      color: AppColors.textMeta,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const AppLineIcon(
              AppIcons.next,
              size: AppIconSize.inline,
            ),
          ],
        ),
      ),
    );
  }

  String get _supportingText {
    if (rating != null && rating! > 0 && reviewCount > 0) {
      return '${rating!.toStringAsFixed(1)} de 5 · $reviewCount '
          '${reviewCount == 1 ? 'opinión' : 'opiniones'}';
    }
    return 'Conoce la experiencia de otros clientes';
  }
}
