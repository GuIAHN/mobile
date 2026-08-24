import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../skeleton_loader.dart';

/// Responsive, non-scrollable grid used to compose dashboard KPI cards.
class DashboardMetricGrid extends StatelessWidget {
  const DashboardMetricGrid({
    super.key,
    required this.children,
    this.baseItemExtent = 160,
    this.scaledItemGrowth = 112,
    this.mainAxisSpacing = AppSpacing.md,
    this.crossAxisSpacing = AppSpacing.md,
  });

  final List<Widget> children;
  final double baseItemExtent;
  final double scaledItemGrowth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final scaleGrowth = (scale - 1).clamp(0.0, 2.0);

    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: _columnsFor(constraints.maxWidth),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisExtent: baseItemExtent + (scaleGrowth * scaledItemGrowth),
        children: children,
      ),
    );
  }
}

/// Skeleton counterpart that keeps loading and data layouts aligned.
class DashboardMetricSkeletonGrid extends StatelessWidget {
  const DashboardMetricSkeletonGrid({
    super.key,
    required this.itemCount,
    required this.keyPrefix,
    this.itemExtent = 160,
    this.mainAxisSpacing = AppSpacing.md,
    this.crossAxisSpacing = AppSpacing.md,
  });

  final int itemCount;
  final String keyPrefix;
  final double itemExtent;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GridView.count(
        crossAxisCount: _columnsFor(constraints.maxWidth),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisExtent: itemExtent,
        children: List.generate(
          itemCount,
          (index) => SkeletonBox(
            key: Key('$keyPrefix-$index'),
            height: itemExtent,
            width: double.infinity,
            borderRadius: AppSpacing.radiusLg,
          ),
        ),
      ),
    );
  }
}

int _columnsFor(double maxWidth) {
  if (maxWidth < 310) return 1;
  if (maxWidth >= 700) return 3;
  return 2;
}
