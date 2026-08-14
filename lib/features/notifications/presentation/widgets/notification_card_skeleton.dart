import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class NotificationCardSkeleton extends StatelessWidget {
  const NotificationCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget shape({required double width, required double height}) {
      if (reduceMotion) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }
      return SkeletonBox(
        width: width,
        height: height,
        borderRadius: 8,
      );
    }

    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDecorations.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: ColoredBox(color: AppColors.primaryMuted),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reduceMotion)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  )
                else
                  const SkeletonBox(
                    width: 48,
                    height: 48,
                    borderRadius: 14,
                  ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shape(width: 132, height: 16),
                      const SizedBox(height: AppSpacing.sm),
                      shape(width: double.infinity, height: 12),
                      const SizedBox(height: AppSpacing.xs),
                      shape(width: 180, height: 12),
                      const SizedBox(height: AppSpacing.sm),
                      shape(width: 112, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
