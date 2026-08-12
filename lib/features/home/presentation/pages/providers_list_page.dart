import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../providers/home_providers.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/home_list_header.dart';
import '../widgets/vehicle_compatibility_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// Pantalla completa de listado de proveedores (Talleres o Mecánicos).
/// Contiene el buscador, filtros y la lista de resultados.
class ProvidersListPage extends ConsumerStatefulWidget {
  final ServiceType serviceType;

  const ProvidersListPage({super.key, required this.serviceType});

  @override
  ConsumerState<ProvidersListPage> createState() => _ProvidersListPageState();
}

class _ProvidersListPageState extends ConsumerState<ProvidersListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Sincronizar el tipo de servicio y limpiar estado de búsqueda previo
      ref.read(selectedServiceTypeProvider.notifier).state = widget.serviceType;
      ref.read(searchQueryProvider.notifier).state = '';
      ref.read(homeFiltersProvider.notifier).state = const HomeFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final currentFilters = ref.read(homeFiltersProvider);
    final result = await showModalBottomSheet<HomeFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (_) => FiltersSheet(
        initialFilters: currentFilters,
        serviceType: widget.serviceType,
      ),
    );

    if (result != null) {
      ref.read(homeFiltersProvider.notifier).state = result;
    }
  }

  String get _title => widget.serviceType == ServiceType.workshops
      ? 'Talleres'
      : 'Mecánicos';

  @override
  Widget build(BuildContext context) {
    final filteredItemsAsync = ref.watch(filteredHomeItemsProvider);
    final filters = ref.watch(homeFiltersProvider);
    final user = ref.watch(authProvider).user;
    final isConsumer = user == null || user.role.isConsumer;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Barra superior con botón de regreso ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _title,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Buscador + filtros ────────────────────────────────────────
            HomeSearchBar(
              searchController: _searchController,
              activeFilters: filters.activeCount,
              onFilterTap: _openFilters,
            ),

            // ── Lista de resultados ───────────────────────────────────────
            Expanded(
              child: ListView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  if (isConsumer) const VehicleCompatibilityBar(),

                  HomeListHeader(
                    itemCount: filteredItemsAsync.value?.length ?? 0,
                    hasActiveFilters: filters.activeCount > 0,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: filteredItemsAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return _buildEmptyState();
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              StaggeredEntrance(
                                index: i,
                                child: ItemCard(item: items[i]),
                              ),
                          ],
                        );
                      },
                      loading: () => const Column(
                        children: [
                          ItemCardSkeleton(),
                          ItemCardSkeleton(),
                          ItemCardSkeleton(),
                        ],
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Text(
                          'Error al cargar: $err',
                          textAlign: TextAlign.center,
                          style:
                              GoogleFonts.hankenGrotesk(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              ref.read(searchQueryProvider.notifier).state = '';
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
}
