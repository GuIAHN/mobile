import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../../domain/entities/home_filters.dart';
import '../providers/home_providers.dart';
import '../widgets/filters_sheet.dart';
import '../widgets/item_card.dart';
import '../widgets/home_list_header.dart';
import '../widgets/vehicle_compatibility_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// Pantalla completa de listado de proveedores (Talleres o Mecánicos).
/// Contiene el buscador, filtros y la lista de resultados.
///
/// La lista se virtualiza con [SliverList.builder] (antes construía un
/// Column con todos los ítems de una sola vez) y el buscador queda fijo en
/// un header adherido mientras se hace scroll por los resultados.
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

  Future<void> _handleRefresh() async {
    ref.invalidate(homeItemsProvider(widget.serviceType));
    try {
      await ref.read(homeItemsProvider(widget.serviceType).future);
    } catch (_) {
      // El error ya queda reflejado en el AsyncValue; el indicador de
      // refresco solo necesita completar.
    }
  }

  String get _title =>
      widget.serviceType == ServiceType.workshops ? 'Talleres' : 'Mecánicos';

  @override
  Widget build(BuildContext context) {
    final filteredItemsAsync = ref.watch(filteredHomeItemsProvider);
    final filters = ref.watch(homeFiltersProvider);
    final query = ref.watch(searchQueryProvider);
    final user = ref.watch(authProvider).user;
    final isConsumer = user == null || user.role.isConsumer;
    final topInset = MediaQuery.of(context).padding.top;
    final titleRowHeight = _titleRowHeight(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                extent: topInset + titleRowHeight + _kSearchRowHeight,
                child: _StickyHeaderContent(
                  title: _title,
                  titleRowHeight: titleRowHeight,
                  searchController: _searchController,
                  hintText: widget.serviceType.hint,
                  activeFilters: filters.activeCount,
                  onFilterTap: _openFilters,
                  onChanged: (value) =>
                      ref.read(searchQueryProvider.notifier).state = value,
                ),
              ),
            ),
            if (isConsumer)
              const SliverToBoxAdapter(child: VehicleCompatibilityBar()),
            SliverToBoxAdapter(
              child: HomeListHeader(
                itemCount: filteredItemsAsync.valueOrNull?.length ?? 0,
                hasActiveFilters: filters.activeCount > 0,
              ),
            ),
            filteredItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyResultsState(
                      query: query,
                      hasFilters: filters.activeCount > 0,
                      onClearQuery: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                      onClearFilters: () => ref
                          .read(homeFiltersProvider.notifier)
                          .state = const HomeFilters(),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) => StaggeredEntrance(
                      index: index,
                      child: ItemCard(item: items[index]),
                    ),
                  ),
                );
              },
              loading: () => const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      ItemCardSkeleton(),
                      ItemCardSkeleton(),
                      ItemCardSkeleton(),
                    ],
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: ErrorView(
                    message: 'No pudimos cargar los resultados.',
                    onRetry: () =>
                        ref.invalidate(homeItemsProvider(widget.serviceType)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _titleRowHeight(BuildContext context) {
    final style = AppTypography.h1;
    final scaledLineHeight = MediaQuery.textScalerOf(context).scale(
          style.fontSize ?? 22,
        ) *
        (style.height ?? 1);

    return math.max(
      _kTitleRowHeight,
      _kTitleTopPadding + math.max(_kBackButtonSize, scaledLineHeight),
    );
  }
}

const double _kTitleRowHeight = 56;
const double _kTitleTopPadding = 8;
const double _kBackButtonSize = 48;
// AppSearchField mide 68 dp: 12 dp de padding superior, 52 dp del control
// y 4 dp de padding inferior. El extent del sliver debe coincidir exactamente
// con la altura pintada por su hijo o Flutter invalida la geometría.
const double _kSearchRowHeight = 68;

/// Header fijo: fila de título + botón de regreso, y buscador con filtros.
/// Permanece visible mientras se hace scroll por los resultados para que la
/// búsqueda siga siendo alcanzable.
class _StickyHeaderContent extends StatelessWidget {
  final String title;
  final double titleRowHeight;
  final TextEditingController searchController;
  final String hintText;
  final int activeFilters;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onChanged;

  const _StickyHeaderContent({
    required this.title,
    required this.titleRowHeight,
    required this.searchController,
    required this.hintText,
    required this.activeFilters,
    required this.onFilterTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: titleRowHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  _kTitleTopPadding,
                  20,
                  0,
                ),
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
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppSearchField(
              controller: searchController,
              hintText: hintText,
              onChanged: onChanged,
              activeFilters: activeFilters,
              onFilterTap: onFilterTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double extent;
  final Widget child;

  const _StickyHeaderDelegate({required this.extent, required this.child});

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return extent != oldDelegate.extent || child != oldDelegate.child;
  }
}

/// Estado vacío honesto: distingue "sin resultados por texto buscado" de
/// "sin resultados por filtros" para que la acción resuelva la causa real.
class _EmptyResultsState extends StatelessWidget {
  final String query;
  final bool hasFilters;
  final VoidCallback onClearQuery;
  final VoidCallback onClearFilters;

  const _EmptyResultsState({
    required this.query,
    required this.hasFilters,
    required this.onClearQuery,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;

    if (hasQuery) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          title: 'Sin resultados para "$query"',
          subtitle: 'Prueba con otro término de búsqueda.',
          icon: Icons.search_off_rounded,
          action: SizedBox(
            width: 200,
            height: 44,
            child: OutlinedButton(
              onPressed: onClearQuery,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Limpiar búsqueda', style: AppTypography.label),
            ),
          ),
        ),
      );
    }

    if (hasFilters) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: EmptyState(
          title: 'Sin resultados con estos filtros',
          subtitle: 'Prueba ampliando el radio o quitando algún filtro.',
          icon: Icons.filter_alt_off_rounded,
          action: SizedBox(
            width: 180,
            height: 44,
            child: ElevatedButton(
              onPressed: onClearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Restablecer filtros',
                  style: AppTypography.label.copyWith(color: Colors.white)),
            ),
          ),
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: EmptyState(
        title: 'Aún no hay resultados en tu zona',
        subtitle:
            'Vuelve a intentarlo más tarde o amplía el radio de búsqueda.',
        icon: Icons.explore_off_rounded,
      ),
    );
  }
}
