import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/home_providers.dart';

class HomeSearchBar extends ConsumerWidget {
  final TextEditingController searchController;
  final int activeFilters;
  final VoidCallback onFilterTap;

  const HomeSearchBar({
    super.key,
    required this.searchController,
    required this.activeFilters,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Esquinas de 12px
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded,
                color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                },
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  filled: false,
                  isCollapsed: true,
                  hintText: selectedType.hint,
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (searchQuery.isNotEmpty) ...[
              IconButton(
                tooltip: 'Limpiar búsqueda',
                onPressed: () {
                  searchController.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
                icon: const Icon(Icons.cancel_rounded,
                    color: AppColors.textDisabled, size: 18),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
            // Botón de filtros integrado en la misma barra
            Semantics(
              button: true,
              label: activeFilters > 0
                  ? 'Filtros de búsqueda, $activeFilters activos'
                  : 'Filtros de búsqueda',
              child: GestureDetector(
                onTap: onFilterTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: activeFilters > 0
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Container(
                            width: 14,
                            height: 14,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$activeFilters',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
    );
  }
}
