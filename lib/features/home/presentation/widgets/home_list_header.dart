import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../providers/home_providers.dart';

class HomeListHeader extends ConsumerWidget {
  final int itemCount;

  const HomeListHeader({
    super.key,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final isLocationShared = ref.watch(isLocationSharedProvider);
    final usesSavedLocation =
        ref.watch(currentRoleProvider).usesSavedLocationForSearch;
    final title = usesSavedLocation
        ? '${selectedType.label} cerca de tu negocio'
        : isLocationShared
            ? '${selectedType.label} cerca de ti'
            : '${selectedType.label} disponibles';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            liveRegion: true,
            label: '$itemCount resultados',
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$itemCount',
                  style: AppTypography.meta.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
