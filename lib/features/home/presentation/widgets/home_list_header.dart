import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/sort_option.dart';
import '../providers/home_providers.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/domain/entities/specialty.dart';
import '../../../../shared/widgets/app_chip.dart';

class HomeListHeader extends ConsumerWidget {
  final int itemCount;
  final bool hasActiveFilters;

  const HomeListHeader({
    super.key,
    required this.itemCount,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final filters = ref.watch(homeFiltersProvider);
    final isLocationShared = ref.watch(isLocationSharedProvider);
    final title = isLocationShared
        ? '${selectedType.label} cerca de ti'
        : '${selectedType.label} disponibles';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '$itemCount',
                            style: AppTypography.meta.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilters)
                Semantics(
                  button: true,
                  label: 'Quitar todos los filtros',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(homeFiltersProvider.notifier).state =
                          const HomeFilters();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 44),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close_rounded,
                              size: 14, color: AppColors.primaryInk),
                          const SizedBox(width: 3),
                          Text(
                            'Quitar filtros',
                            style: AppTypography.label.copyWith(
                              fontSize: 13,
                              color: AppColors.primaryInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasActiveFilters) _buildActiveFilterChips(ref, filters),
      ],
    );
  }

  Widget _buildActiveFilterChips(WidgetRef ref, HomeFilters filters) {
    final chips = <Widget>[];
    final specialtiesAsync = ref.watch(specialtiesProvider);

    void addChip(String label, VoidCallback onRemove) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AppChip(label: label, selected: true, onRemove: onRemove),
        ),
      );
    }

    // El valor por defecto de sortBy es SortOption.rating (ver HomeFilters),
    // no cercania: comparar contra rating es lo que hace que este chip
    // solo aparezca cuando el usuario realmente cambió el orden.
    if (filters.sortBy != SortOption.rating) {
      addChip(
        filters.sortBy.label,
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(sortBy: SortOption.rating),
      );
    }

    if (filters.radioKm != 20.0) {
      addChip(
        '≤ ${filters.radioKm.toInt()} km',
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(radioKm: 20.0),
      );
    }

    if (filters.minRating != 0.0) {
      addChip(
        '${filters.minRating}+ ★',
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(minRating: 0.0),
      );
    }

    if (filters.specialtyIds.isNotEmpty) {
      specialtiesAsync.whenData((specialties) {
        for (final id in filters.specialtyIds) {
          final specialty = specialties.firstWhere(
            (s) => s.id == id,
            orElse: () => Specialty(id: id, name: id),
          );
          addChip(specialty.name, () {
            final newSpecialties = List<String>.from(filters.specialtyIds)
              ..remove(id);
            ref.read(homeFiltersProvider.notifier).state =
                filters.copyWith(specialtyIds: newSpecialties);
          });
        }
      });
    }

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
        children: chips,
      ),
    );
  }
}
