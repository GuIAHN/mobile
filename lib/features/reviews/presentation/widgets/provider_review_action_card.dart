import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/reviews_providers.dart';
import 'star_rating_input.dart';
import 'write_review_bottom_sheet.dart';

class ProviderReviewActionCard extends ConsumerWidget {
  final String targetId;
  final String providerProfileId;
  final String providerName;

  const ProviderReviewActionCard({
    super.key,
    required this.targetId,
    required this.providerProfileId,
    required this.providerName,
  });

  Future<void> _openForm(BuildContext context, WidgetRef ref) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewBottomSheet(
        targetId: targetId,
        providerName: providerName,
      ),
    );
    if (saved == true) {
      ref.invalidate(myReviewProvider(targetId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myReview = ref.watch(myReviewProvider(targetId));
    final contacted =
        ref.watch(hasContactedProviderProvider(providerProfileId));

    if (myReview.isLoading || contacted.isLoading) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    }

    if (myReview.hasError || contacted.hasError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'No pudimos cargar tu valoración.',
                style: AppTypography.bodySm,
              ),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(myReviewProvider(targetId));
                ref.invalidate(hasContactedProviderProvider(providerProfileId));
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AppColors.primaryInk,
              ),
              child: Text(
                'Reintentar',
                style: AppTypography.label.copyWith(
                  color: AppColors.primaryInk,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final status = myReview.valueOrNull;
    final canReview = contacted.valueOrNull ?? false;
    if (status == null || (!status.hasReviewed && !canReview)) {
      return const SizedBox.shrink();
    }

    final review = status.review;
    return Semantics(
      container: true,
      label: review == null
          ? 'Puedes valorar tu experiencia con $providerName'
          : 'Tu valoración para $providerName es de ${review.rating} estrellas',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: AppColors.warningInk),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review == null
                            ? 'Valora tu experiencia'
                            : 'Tu valoración',
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        review == null
                            ? 'Ayuda a otros conductores a elegir mejor.'
                            : 'Puedes actualizarla cuando quieras.',
                        style: AppTypography.bodySm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                key: const Key('provider-own-review-stars'),
                child: StarRatingInput(
                  rating: review.rating,
                  readOnly: true,
                  size: 24,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeightMd,
              child: OutlinedButton.icon(
                onPressed: () => _openForm(context, ref),
                icon: Icon(
                  review == null
                      ? Icons.rate_review_outlined
                      : Icons.edit_rounded,
                  size: 20,
                ),
                label: Text(
                  review == null ? 'DEJAR VALORACIÓN' : 'EDITAR VALORACIÓN',
                  style: AppTypography.label.copyWith(
                    color: AppColors.primaryInk,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryInk,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
