import 'dart:async';
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
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// Pantalla completa de listado de proveedores (Talleres o Mecánicos).
/// Contiene el buscador, filtros y la lista de resultados.
///
/// La grilla virtualizada carga páginas del servidor al acercarse al final.
/// El buscador queda fijo mientras se hace scroll por los resultados.
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
    _scrollController.addListener(_loadNearEnd);
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
      _resetScroll();
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _loadNearEnd() {
    if (!_scrollController.hasClients) return;
    final state =
        ref.read(paginatedProvidersProvider(widget.serviceType)).valueOrNull;
    if (state == null || state.loadMoreError != null) return;
    if (_scrollController.position.extentAfter < 600) {
      unawaited(ref
          .read(paginatedProvidersProvider(widget.serviceType).notifier)
          .loadMore());
    }
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(paginatedProvidersProvider(widget.serviceType));
    try {
      await ref.read(paginatedProvidersProvider(widget.serviceType).future);
    } catch (_) {
      // El error ya queda reflejado en el AsyncValue; el indicador de
      // refresco solo necesita completar.
    }
  }

  String get _title =>
      widget.serviceType == ServiceType.workshops ? 'Talleres' : 'Mecánicos';

  @override
  Widget build(BuildContext context) {
    final filteredItemsAsync =
        ref.watch(filteredProvidersProvider(widget.serviceType));
    final pagination =
        ref.watch(paginatedProvidersProvider(widget.serviceType));
    final listState = pagination.valueOrNull;
    ref.listen(homeFiltersProvider, (_, __) => _resetScroll());
    final filters = ref.watch(homeFiltersProvider);
    final query = ref.watch(searchQueryProvider);
    // Text search is local because this endpoint has no text query. Scan the
    // remaining pages rather than reporting a false empty result after page 1.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(paginatedProvidersProvider(widget.serviceType));
      final value = current.valueOrNull;
      if (current.isLoading ||
          value == null ||
          value.isLoadingMore ||
          value.loadMoreError != null) {
        return;
      }
      if (query.trim().isNotEmpty && value.hasMore) {
        unawaited(ref
            .read(paginatedProvidersProvider(widget.serviceType).notifier)
            .loadMore());
      } else {
        _loadNearEnd();
      }
    });
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
                  onFilterTap: _openFilters,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                    _resetScroll();
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: HomeListHeader(
                itemCount: query.trim().isEmpty
                    ? listState?.total ??
                        filteredItemsAsync.valueOrNull?.length ??
                        0
                    : filteredItemsAsync.valueOrNull?.length ?? 0,
              ),
            ),
            filteredItemsAsync.when(
              data: (items) {
                if (items.isEmpty && !(listState?.hasMore ?? false)) {
                  return SliverToBoxAdapter(
                    child: _EmptyResultsState(
                      query: query,
                      hasFilters: filters.activeCount > 0,
                      onClearQuery: () {
                        _searchController.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        _resetScroll();
                      },
                      onClearFilters: () {
                        ref.read(homeFiltersProvider.notifier).state =
                            const HomeFilters();
                        _resetScroll();
                      },
                    ),
                  );
                }
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final useSingleColumn =
                    MediaQuery.sizeOf(context).width < 360 || textScale > 1.35;
                final cardExtent = useSingleColumn
                    ? (330 + ((textScale - 1).clamp(0, 1) * 90)).toDouble()
                    : 258.0;

                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: useSingleColumn ? 1 : 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: cardExtent,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => StaggeredEntrance(
                            index: index % 20,
                            child: ItemCard(
                                key: ValueKey(items[index].id),
                                item: items[index]),
                          ),
                          childCount: items.length,
                          addAutomaticKeepAlives: false,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SafeArea(
                        top: false,
                        child: _LoadMoreFooter(
                          state: listState,
                          reduceMotion: MediaQuery.disableAnimationsOf(context),
                          onLoadMore: () => ref
                              .read(
                                  paginatedProvidersProvider(widget.serviceType)
                                      .notifier)
                              .loadMore(),
                        ),
                      ),
                    ),
                  ],
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
                    onRetry: () => ref.invalidate(
                        paginatedProvidersProvider(widget.serviceType)),
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

class _LoadMoreFooter extends StatelessWidget {
  final ProvidersListState? state;
  final bool reduceMotion;
  final VoidCallback onLoadMore;

  const _LoadMoreFooter(
      {required this.state,
      required this.reduceMotion,
      required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    final value = state;
    if (value == null || value.items.isEmpty && !value.hasMore) {
      return const SizedBox(height: 24);
    }
    final message = value.loadMoreError != null
        ? 'No pudimos cargar más resultados.'
        : value.isLoadingMore
            ? 'Cargando más resultados…'
            : value.hasMore
                ? value.total == null
                    ? '${value.items.length} resultados cargados'
                    : '${value.items.length} de ${value.total} resultados'
                : 'Has visto todos los resultados';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Semantics(
            liveRegion: true,
            child: Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.textPrimary)),
          ),
          if (value.isLoadingMore && !reduceMotion)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary)),
            ),
          if (value.hasMore && !value.isLoadingMore)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: onLoadMore,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  foregroundColor: AppColors.primary,
                  textStyle: AppTypography.bodySm
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w700),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                    value.loadMoreError != null ? 'Reintentar' : 'Cargar más'),
              ),
            ),
        ],
      ),
    );
  }
}

const double _kTitleTopPadding = 8;
const double _kBackButtonSize = 48;
const double _kTitleRowHeight = 56;
const double _kSearchRowHeight = 72;

/// Header fijo: fila de título + botón de regreso, y buscador con filtros.
/// Permanece visible mientras se hace scroll por los resultados para que la
/// búsqueda siga siendo alcanzable.
class _StickyHeaderContent extends StatelessWidget {
  final String title;
  final double titleRowHeight;
  final TextEditingController searchController;
  final String hintText;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onChanged;

  const _StickyHeaderContent({
    required this.title,
    required this.titleRowHeight,
    required this.searchController,
    required this.hintText,
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
    // Persistent headers receive loose box constraints. Expand the visual
    // child to the same extent advertised by this delegate so Flutter never
    // computes a larger layoutExtent than paintExtent.
    return SizedBox.expand(child: child);
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
            height: 48,
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
            height: 48,
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
