import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/sort_option.dart';
import '../providers/home_providers.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/domain/entities/specialty.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${selectedType.label} cerca de ti',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$itemCount',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (hasActiveFilters)
                GestureDetector(
                  onTap: () {
                    ref.read(homeFiltersProvider.notifier).state =
                        const HomeFilters();
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Quitar filtros',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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

    void addChip(Widget content, VoidCallback onRemove) {
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.cancel_rounded,
                    size: 16, color: AppColors.textDisabled),
              ),
            ],
          ),
        ),
      );
    }

    if (filters.sortBy != SortOption.cercania) {
      addChip(
        Text(
          filters.sortBy.label,
          style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(sortBy: SortOption.cercania),
      );
    }

    if (filters.radioKm != 20.0) {
      addChip(
        Text(
          '≤ ${filters.radioKm.toInt()} km',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(radioKm: 20.0),
      );
    }

    if (filters.minRating != 0.0) {
      addChip(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
            const SizedBox(width: 3),
            Text(
              '${filters.minRating}+',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
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
          addChip(
            Text(
              specialty.name,
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            () {
              final newSpecialties = List<String>.from(filters.specialtyIds)
                ..remove(id);
              ref.read(homeFiltersProvider.notifier).state =
                  filters.copyWith(specialtyIds: newSpecialties);
            },
          );
        }
      });
    }

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
        children: chips,
      ),
    );
  }
}
