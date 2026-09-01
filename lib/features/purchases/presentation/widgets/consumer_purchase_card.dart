import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/consumer_purchase.dart';

class ConsumerPurchaseCard extends StatelessWidget {
  const ConsumerPurchaseCard({
    super.key,
    required this.purchase,
    this.onReview,
  });

  final ConsumerPurchase purchase;
  final VoidCallback? onReview;

  String get _statusLabel => switch (purchase.status) {
        PurchaseStatus.bought => 'POR RECIBIR',
        PurchaseStatus.delivered => 'ENTREGADA',
        PurchaseStatus.cancelled => 'CANCELADA',
        PurchaseStatus.unknown => 'COMPRA ACTUALIZADA',
      };

  Color get _statusColor => switch (purchase.status) {
        PurchaseStatus.delivered => AppColors.success,
        PurchaseStatus.cancelled => AppColors.error,
        _ => AppColors.primary,
      };

  IconData get _statusIcon => switch (purchase.status) {
        PurchaseStatus.delivered => AppIcons.success,
        PurchaseStatus.cancelled => AppIcons.cancellation,
        _ => AppIcons.receipt,
      };

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useStackedFooter =
        textScale > 1.3 || MediaQuery.sizeOf(context).width < 360;
    final canReviewCancellation = purchase.status == PurchaseStatus.cancelled &&
        !purchase.hasReviewed &&
        purchase.storeId?.trim().isNotEmpty == true &&
        purchase.conversationId?.trim().isNotEmpty == true;
    final canLeaveReview =
        (purchase.needsReview && purchase.canReview) || canReviewCancellation;
    final canViewReview = purchase.hasReviewed &&
        purchase.reviewTargetId?.trim().isNotEmpty == true;
    final showReviewAction =
        onReview != null && (canLeaveReview || canViewReview);
    final partName = purchase.partName?.trim().isNotEmpty == true
        ? purchase.partName!.trim()
        : 'Repuesto comprado';
    final semantics = StringBuffer(
      'Compra de $partName para ${purchase.vehicleName}, $_statusLabel, '
      'tienda ${purchase.storeName}',
    );
    if (purchase.needsReview) semantics.write(', pendiente de reseña');

    final total = Semantics(
      label: purchase.resolvedTotal == null
          ? 'Total sin precio disponible'
          : 'Total ${Formatters.currency(purchase.resolvedTotal!)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOTAL', style: AppTypography.overline),
            const SizedBox(height: AppSpacing.xs),
            Text(
              purchase.resolvedTotal == null
                  ? 'Sin precio'
                  : Formatters.currency(purchase.resolvedTotal!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.h1.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );

    final reviewButton = showReviewAction
        ? SizedBox(
            key: const Key('consumer-purchase-review-action'),
            width: useStackedFooter ? double.infinity : 168,
            height: AppSpacing.buttonHeightMd,
            child: purchase.hasReviewed
                ? OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const AppLineIcon(
                      AppIcons.reviews,
                      size: AppIconSize.inline,
                    ),
                    label: const Text(
                      'Ver reseña',
                      maxLines: 1,
                      softWrap: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      textStyle: AppTypography.label,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onReview,
                    icon: const AppLineIcon(
                      AppIcons.reviews,
                      size: AppIconSize.inline,
                    ),
                    label: const Text(
                      'Dejar reseña',
                      maxLines: 1,
                      softWrap: false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                      textStyle: AppTypography.label,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      shape: const StadiumBorder(),
                    ),
                  ),
          )
        : null;

    return Container(
      key: const Key('consumer-purchase-card'),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            container: true,
            label: semantics.toString(),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PurchaseThumbnail(url: purchase.photoUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                partName,
                                maxLines: textScale > 1.3 ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.title,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppLineIcon(
                              _statusIcon,
                              key: const Key('consumer-purchase-status-icon'),
                              size: AppIconSize.action,
                              color: _statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          purchase.vehicleName,
                          maxLines: textScale > 1.3 ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppLineIcon(
                              AppIcons.store,
                              size: AppIconSize.inline,
                              color: AppColors.textMeta,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                purchase.storeName,
                                maxLines: textScale > 1.3 ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySm,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.border),
          ),
          if (useStackedFooter && reviewButton != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                total,
                const SizedBox(height: AppSpacing.md),
                reviewButton,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: total),
                if (reviewButton != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  reviewButton,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _PurchaseThumbnail extends StatelessWidget {
  const _PurchaseThumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox.square(
        dimension: 88,
        child: ColoredBox(
          color: AppColors.grey50,
          child: url?.trim().isNotEmpty == true
              ? Image.network(
                  url!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => const _VehicleFallback(),
                )
              : const _VehicleFallback(),
        ),
      ),
    );
  }
}

class _VehicleFallback extends StatelessWidget {
  const _VehicleFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: AppLineIcon(
        AppIcons.vehicle,
        size: AppIconSize.feature,
        color: AppColors.grey400,
      ),
    );
  }
}
