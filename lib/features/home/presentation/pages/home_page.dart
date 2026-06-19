import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/home_filters.dart';
import '../../domain/entities/service_type.dart';
import '../../domain/entities/sort_option.dart';
import '../providers/home_providers.dart';
import '../widgets/bottom_burbuja.dart';
import '../widgets/category_selector.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/request_spare_part_form.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Abre la hoja de filtros y guarda el resultado
  Future<void> _openFilters() async {
    final currentFilters = ref.read(homeFiltersProvider);
    final result = await showModalBottomSheet<HomeFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => FiltersSheet(initialFilters: currentFilters),
    );

    if (result != null) {
      ref.read(homeFiltersProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(homeTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Show a friendly welcome greeting if authenticated and not shown yet in this session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && user != null && !ref.read(welcomeShownProvider)) {
        ref.read(welcomeShownProvider.notifier).state = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '¡Hola, ${user.name}!',
                      style: GoogleFonts.hankenGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2000),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            margin: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: 96,
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: activeTab == 0
                  ? _buildHomeTab()
                  : activeTab == 1
                      ? _buildPlaceholderTab(
                          Icons.chat_bubble_outline_rounded,
                          'Chats',
                          'Tus conversaciones de servicio aparecerán aquí.')
                      : _buildPlaceholderTab(
                          Icons.person_outline_rounded,
                          'Mi Perfil',
                          'Configura tus datos, vehículos y preferencias.'),
            ),
          ),
          // Barra de navegación inferior burbuja flotante
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomBurbuja(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final selectedType = ref.watch(selectedServiceTypeProvider);
    final promosAsync = ref.watch(promosProvider(selectedType));
    final filteredItemsAsync = ref.watch(filteredHomeItemsProvider);
    final filters = ref.watch(homeFiltersProvider);
    final isSpareParts = selectedType == ServiceType.spareParts;

    return ListView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
          bottom: 120), // Espaciado extra para no tapar con la barra burbuja
      children: [
        // 1. Header (Logo + Ubicación)
        _buildHeader(),

        // 2. Selector de categoría
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: CategorySelector(),
        ),

        // 3. Barra de búsqueda y botón filtros (solo si no es repuestos)
        if (!isSpareParts) _buildSearchBar(filters.activeCount),

        // 4. Carrusel de Promociones
        promosAsync.when(
          data: (promos) => Padding(
            padding: const EdgeInsets.only(top: 12, left: 20, right: 20),
            child: PromoCarousel(promos: promos),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Si es repuestos, mostramos el formulario de solicitud
        if (isSpareParts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: RequestSparePartForm(
              onSubmitted: () {
                _scrollController.animateTo(
                  0.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                );
              },
            ),
          )
        else ...[
          // 5. Encabezado de la lista
          _buildListHeader(
              filteredItemsAsync.value?.length ?? 0, filters.activeCount > 0),

          // 6. Chips con los filtros aplicados
          if (filters.activeCount > 0) _buildActiveFilterChips(filters),

          // 7. Lista de Items filtrados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: filteredItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: items.map((item) => ItemCard(item: item)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Text(
                  'Error al cargar: $err',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final isLocationShared = ref.watch(isLocationSharedProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          // Logo oficial "GuIA"
          RichText(
            text: TextSpan(
              style: GoogleFonts.hankenGrotesk(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
              children: const [
                TextSpan(text: 'Gu'),
                TextSpan(
                  text: 'IA',
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Toggle de Compartir Ubicación
          GestureDetector(
            onTap: () {
              ref.read(isLocationSharedProvider.notifier).state =
                  !isLocationShared;
            },
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isLocationShared ? AppColors.primaryMuted : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isLocationShared ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isLocationShared
                    ? Icons.location_on
                    : Icons.location_on_outlined,
                color: isLocationShared
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(int activeFilters) {
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
                controller: _searchController,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
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
                  hintText: 'Buscar repuestos, talleres o mecánicos...',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textDisabled,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  });
                },
                child: const Icon(Icons.cancel_rounded,
                    color: AppColors.textDisabled, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            const SizedBox(width: 4),
            // Botón de filtros integrado en la misma barra
            GestureDetector(
              onTap: _openFilters,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader(int itemCount, bool hasActiveFilters) {
    final selectedType = ref.watch(selectedServiceTypeProvider);

    return Padding(
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }

  Widget _buildActiveFilterChips(HomeFilters filters) {
    final chips = <Widget>[];

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

    if (filters.maxDistance != 5.0) {
      addChip(
        Text(
          '≤ ${filters.maxDistance.toInt()} km',
          style: GoogleFonts.hankenGrotesk(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(maxDistance: 5.0),
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

    if (filters.onlyOpen) {
      addChip(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(
              'Abiertos',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success),
            ),
          ],
        ),
        () => ref.read(homeFiltersProvider.notifier).state =
            filters.copyWith(onlyOpen: false),
      );
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: EmptyState(
        title: 'Sin resultados',
        subtitle:
            'Prueba ampliando el rango de búsqueda o modificando tus filtros.',
        icon: Icons.search_off_rounded,
        action: SizedBox(
          width: 180,
          height: 44,
          child: ElevatedButton(
            onPressed: () {
              ref.read(homeFiltersProvider.notifier).state =
                  const HomeFilters();
              setState(() {
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Restablecer filtros',
              style: GoogleFonts.hankenGrotesk(
                  fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(IconData icon, String title, String subtitle) {
    return Center(
      key: ValueKey(title),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: const BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'PRÓXIMAMENTE',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
