import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

/// Skeleton que conserva la silueta del nuevo detalle compacto.
class ServiceProviderDetailSkeleton extends StatelessWidget {
  final bool compact;

  const ServiceProviderDetailSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: !compact || !MediaQuery.disableAnimationsOf(context),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            if (compact)
              const SafeArea(
                  bottom: false, child: SizedBox(height: kToolbarHeight))
            else
              const SkeletonBox(height: 252, borderRadius: 0),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: SkeletonBox(height: 356, borderRadius: 16),
            ),
          ],
        ),
      ),
    );
  }
}
