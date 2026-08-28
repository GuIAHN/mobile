import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_thread.dart';
import '../widgets/chat_thread_card.dart';
import '../widgets/consumer_thread_card.dart';
import '../../../home/presentation/widgets/navigation/bottom_nav_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// Filtro por estado de la solicitud/oferta.
enum _StatusFilter {
  all,
  active,
  closed,
  pending,
  inquiring,
  declined,
  quoted,
  bought,
  delivered,
  cancelled,
  discarded,
}

/// Bandeja comercial reutilizada por Compras (consumidor) y Ventas (tienda).
/// Las conversaciones reales viven en [ConversationsInboxPage].
class RequestManagementPage extends ConsumerStatefulWidget {
  final bool isStore;

  const RequestManagementPage({
    super.key,
    required this.isStore,
  });

  @override
  ConsumerState<RequestManagementPage> createState() =>
      _RequestManagementPageState();
}

class _RequestManagementPageState extends ConsumerState<RequestManagementPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.active;
  bool _initializedProviderFilter = false;

  bool _isExpired(ChatThread thread) {
    final expiresAt = thread.expiresAt;
    return !thread.isOpen ||
        thread.isExpired ||
        (expiresAt != null && !expiresAt.isAfter(DateTime.now()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtro por texto (título de la solicitud o nombre del cliente).
  List<ChatThread> _applySearch(List<ChatThread> threads) {
    if (_query.trim().isEmpty) return threads;
    final q = _query.trim().toLowerCase();
    return threads.where((t) {
      return t.title.toLowerCase().contains(q) ||
          (t.clientName?.toLowerCase().contains(q) ?? false) ||
          (t.subcategory?.toLowerCase().contains(q) ?? false) ||
          (t.details?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Filtro por estado.
  List<ChatThread> _applyStatus(List<ChatThread> threads, bool isStore) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return threads;
      case _StatusFilter.active:
        return threads.where((t) => t.isOpen && !t.isExpired).toList();
      case _StatusFilter.closed:
        return threads.where((t) => !t.isOpen || t.isExpired).toList();
      case _StatusFilter.pending:
        return threads
            .where(
              (t) =>
                  !_isExpired(t) &&
                  (t.matchState == 'PENDING' || t.matchState == 'INQUIRING'),
            )
            .toList();
      case _StatusFilter.inquiring:
        return threads.where((t) => t.matchState == 'INQUIRING').toList();
      case _StatusFilter.declined:
        return threads.where((t) => t.matchState == 'DECLINED').toList();
      case _StatusFilter.quoted:
        return isStore
            ? threads.where((t) => t.matchState == 'QUOTED').toList()
            : threads.where((t) => t.bestOfferPrice != null).toList();
      case _StatusFilter.bought:
        return threads
            .where((t) => isStore
                ? t.offerStatus == 'BOUGHT'
                : t.bestOfferStatus == 'BOUGHT' ||
                    t.bestOfferStatus == 'DELIVERED' ||
                    t.bestOfferStatus == 'CANCELLED')
            .toList();
      case _StatusFilter.delivered:
        return threads
            .where((t) =>
                t.offerStatus == 'DELIVERED' && (!isStore || !t.isExpired))
            .toList();
      case _StatusFilter.cancelled:
        return threads
            .where((t) => isStore
                ? t.offerStatus == 'CANCELLED' && !t.isExpired
                : t.bestOfferStatus == 'CANCELLED')
            .toList();
      case _StatusFilter.discarded:
        return threads.where((t) => t.offerStatus == 'DISCARDED').toList();
    }
  }

  String _mapFilterToParam(_StatusFilter filter, bool isProvider) {
    if (isProvider) {
      switch (filter) {
        case _StatusFilter.pending:
          return 'PENDING';
        case _StatusFilter.inquiring:
          return 'INQUIRING';
        case _StatusFilter.declined:
          return 'DECLINED';
        case _StatusFilter.quoted:
          return 'QUOTED';
        case _StatusFilter.bought:
          return 'BOUGHT';
        case _StatusFilter.delivered:
          return 'DELIVERED';
        case _StatusFilter.cancelled:
          return 'CANCELLED';
        case _StatusFilter.discarded:
          return 'DISCARDED';
        case _StatusFilter.all:
        default:
          return 'ALL';
      }
    } else {
      switch (filter) {
        case _StatusFilter.active:
          return 'OPEN';
        case _StatusFilter.quoted:
          return 'WITH_OFFER';
        case _StatusFilter.bought:
          return 'BOUGHT';
        case _StatusFilter.closed:
          return 'CLOSED';
        case _StatusFilter.cancelled:
          return 'CANCELLED';
        case _StatusFilter.all:
        default:
          return 'ALL';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStore = widget.isStore;
    final threadsAsync = ref.watch(
      isStore ? storeSalesRequestsProvider : consumerRequestsProvider,
    );

    if (isStore && !_initializedProviderFilter) {
      _statusFilter = _StatusFilter.pending;
      _initializedProviderFilter = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: threadsAsync.when(
          // Al cambiar un filtro, Riverpod conserva el último resultado mientras
          // solicita el nuevo. Así no reemplazamos toda la pantalla por el
          // skeleton ni hacemos desaparecer los controles.
          skipLoadingOnReload: true,
          loading: () => _buildLoadingState(isStore),
          error: (err, _) => _buildErrorState(err.toString(), isStore),
          data: (res) => _buildThreadsList(res.threads, isStore, res.counts),
        ),
      ),
    );
  }

  Future<void> _refreshRequests() {
    return ref.refresh(
      widget.isStore
          ? storeSalesRequestsProvider.future
          : consumerRequestsProvider.future,
    );
  }

  Widget _buildLoadingState(bool isProvider) {
    return Column(
      children: [
        _buildHeader(
          isProvider: isProvider,
          isLoading: true,
          activeCount: 0,
        ),
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              bottomNavContentInset(context) + 24,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => StaggeredEntrance(
              index: index,
              child: ThreadCardSkeleton(isStore: isProvider),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String err, bool isProvider) {
    return Column(
      children: [
        _buildHeader(
          isProvider: isProvider,
          isLoading: false,
          activeCount: 0,
        ),
        Expanded(
          child: Center(
            child: Text(
              'Error al cargar solicitudes: $err',
              style: GoogleFonts.hankenGrotesk(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreadsList(
    List<ChatThread> threads,
    bool isProvider,
    Map<String, int> counts,
  ) {
    final searchFiltered = _applySearch(threads);
    final activeCount = counts['open'] ??
        searchFiltered.where((t) => t.isOpen && !t.isExpired).length;
    // El contador debe representar exactamente lo que puede abrirse desde
    // Pendientes. No usamos los conteos del servidor porque una respuesta
    // desactualizada podría seguir incluyendo solicitudes ya vencidas.
    final pendingCount = searchFiltered
        .where(
          (t) =>
              !_isExpired(t) &&
              (t.matchState == 'PENDING' || t.matchState == 'INQUIRING'),
        )
        .length;
    final quotedCount = counts['quoted'] ??
        counts['withOffer'] ??
        searchFiltered
            .where((t) => isProvider ? t.hasOffer : t.bestOfferPrice != null)
            .length;
    final boughtCount = counts['bought'] ??
        searchFiltered
            .where((t) => isProvider
                ? t.offerStatus == 'BOUGHT'
                : t.bestOfferStatus == 'BOUGHT' ||
                    t.bestOfferStatus == 'DELIVERED' ||
                    t.bestOfferStatus == 'CANCELLED')
            .length;
    final deliveredCount = counts['delivered'] ??
        searchFiltered.where((t) => t.offerStatus == 'DELIVERED').length;
    final cancelledCount = counts['cancelled'] ??
        searchFiltered
            .where((t) => isProvider
                ? t.offerStatus == 'CANCELLED'
                : t.bestOfferStatus == 'CANCELLED')
            .length;
    final visible = _applyStatus(searchFiltered, isProvider);

    return Column(
      children: [
        _buildHeader(
          isProvider: isProvider,
          isLoading: false,
          activeCount: activeCount,
          pendingCount: pendingCount,
          quotedCount: quotedCount,
          boughtCount: boughtCount,
          deliveredCount: deliveredCount,
          cancelledCount: cancelledCount,
        ),
        Expanded(
          child: _buildListBody(threads, searchFiltered, visible, isProvider),
        ),
      ],
    );
  }

  Widget _buildListBody(
    List<ChatThread> threads,
    List<ChatThread> searchFiltered,
    List<ChatThread> visible,
    bool isProvider,
  ) {
    Widget? emptyWidget;

    // Sin ninguna solicitud/oferta en absoluto.
    if (threads.isEmpty) {
      emptyWidget = EmptyState(
        title: isProvider
            ? 'Sin solicitudes de venta'
            : 'Aún no tienes solicitudes',
        subtitle: isProvider
            ? 'No hay solicitudes activas para cotizar en este momento.'
            : 'Cuando solicites un repuesto, podrás darle seguimiento desde aquí.',
        icon: isProvider ? Icons.inbox_outlined : Icons.local_offer_outlined,
      );
    } else if (searchFiltered.isEmpty) {
      // La búsqueda por texto no arrojó resultados.
      emptyWidget = EmptyState(
        title: 'Sin resultados',
        subtitle: 'No encontramos nada para "$_query".',
        icon: Icons.search_off_rounded,
      );
    } else if (visible.isEmpty) {
      // El filtro de estado dejó la lista vacía.
      emptyWidget = const EmptyState(
        title: 'Sin solicitudes en esta categoría',
        subtitle: 'No hay elementos para el filtro seleccionado por ahora.',
        icon: Icons.filter_alt_off_outlined,
      );
    }

    if (emptyWidget != null) {
      return RefreshIndicator(
        onRefresh: _refreshRequests,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: EdgeInsets.only(
            bottom: bottomNavContentInset(context) + 24,
          ),
          children: [
            const SizedBox(height: 80),
            emptyWidget,
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshRequests,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          bottomNavContentInset(context) + 24,
        ),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final thread = visible[index];
          return StaggeredEntrance(
            key: ValueKey('request-${thread.id}'),
            index: index,
            child: isProvider
                ? ChatThreadCard(
                    thread: thread,
                    onViewDetail: () {
                      context.push(RouteNames.saleDetailPath(thread.id));
                    },
                    onTap: () {
                      if (thread.conversationId != null &&
                          thread.conversationId!.isNotEmpty) {
                        context.push(
                          RouteNames.chatConversationPath(
                            thread.conversationId!,
                          ),
                        );
                      } else {
                        context.push(RouteNames.saleDetailPath(thread.id));
                      }
                    },
                  )
                : ConsumerThreadCard(
                    thread: thread,
                    onTap: () {
                      context.push(RouteNames.purchaseDetailPath(thread.id));
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({
    required bool isProvider,
    required bool isLoading,
    required int activeCount,
    int pendingCount = 0,
    int quotedCount = 0,
    int boughtCount = 0,
    int deliveredCount = 0,
    int cancelledCount = 0,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          _buildSearchBar(isLoading, isProvider),

          if (!isLoading) ...[
            const SizedBox(height: 12),
            _StatusFilterSelector(
              isProvider: isProvider,
              selected: _statusFilter,
              activeCount: activeCount,
              pendingCount: pendingCount,
              quotedCount: quotedCount,
              boughtCount: boughtCount,
              deliveredCount: deliveredCount,
              cancelledCount: cancelledCount,
              onChanged: (f) {
                setState(() => _statusFilter = f);
                final param = _mapFilterToParam(f, isProvider);
                if (isProvider) {
                  ref.read(storeStatusFilterProvider.notifier).state = param;
                } else {
                  ref.read(consumerStatusFilterProvider.notifier).state = param;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isLoading, bool isProvider) {
    return Container(
      key: const Key('request-search-bar'),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: !isLoading,
              onChanged: (val) => setState(() => _query = val),
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintText: isProvider
                    ? 'Buscar por cliente o solicitud...'
                    : 'Buscar por tienda o solicitud...',
                hintStyle: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.cancel_rounded,
                    color: AppColors.textDisabled, size: 17),
              ),
            ),
        ],
      ),
    );
  }
}

/// Selector compacto de estado. Mantiene visible la selección actual y lleva
/// las opciones a un bottom sheet con blancos táctiles cómodos.
class _StatusFilterSelector extends StatelessWidget {
  final bool isProvider;
  final _StatusFilter selected;
  final int activeCount;
  final int pendingCount;
  final int quotedCount;
  final int boughtCount;
  final int deliveredCount;
  final int cancelledCount;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusFilterSelector({
    this.isProvider = false,
    required this.selected,
    required this.activeCount,
    this.pendingCount = 0,
    this.quotedCount = 0,
    this.boughtCount = 0,
    this.deliveredCount = 0,
    this.cancelledCount = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = isProvider
        ? <({String label, int count, _StatusFilter filter})>[
            (
              label: 'Pendientes',
              count: pendingCount,
              filter: _StatusFilter.pending,
            ),
            (
              label: 'Cotizadas',
              count: quotedCount,
              filter: _StatusFilter.quoted,
            ),
            (
              label: 'Vendidas',
              count: boughtCount,
              filter: _StatusFilter.bought,
            ),
            (
              label: 'Entregadas',
              count: deliveredCount,
              filter: _StatusFilter.delivered,
            ),
            (
              label: 'Canceladas',
              count: cancelledCount,
              filter: _StatusFilter.cancelled,
            ),
          ]
        : <({String label, int count, _StatusFilter filter})>[
            (
              label: 'Activas',
              count: activeCount,
              filter: _StatusFilter.active,
            ),
            (
              label: 'Cotizadas',
              count: quotedCount,
              filter: _StatusFilter.quoted,
            ),
            (
              label: 'Compradas',
              count: boughtCount,
              filter: _StatusFilter.bought,
            ),
            (
              label: 'Canceladas',
              count: cancelledCount,
              filter: _StatusFilter.cancelled,
            ),
          ];
    final selectedOption = options.firstWhere(
      (option) => option.filter == selected,
      orElse: () => options.first,
    );

    return Semantics(
      button: true,
      label:
          'Filtrar por estado. Seleccionado: ${selectedOption.label}, ${selectedOption.count}',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: Key(
            isProvider
                ? 'store-sales-filter-group'
                : 'consumer-purchase-filter-group',
          ),
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showOptions(context, options),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ESTADO',
                        maxLines: 1,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedOption.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusCount(count: selectedOption.count, isSelected: true),
                const SizedBox(width: 10),
                const AppLineIcon(
                  AppIcons.expand,
                  size: AppIconSize.inline,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    List<({String label, int count, _StatusFilter filter})> options,
  ) async {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final choice = await showModalBottomSheet<_StatusFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      sheetAnimationStyle: AnimationStyle(
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
        reverseDuration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                child: Text(
                  'Filtrar por estado',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  key: const Key('status-filter-list'),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    for (final option in options)
                      Semantics(
                        button: true,
                        selected: option.filter == selected,
                        label:
                            '${option.label}, ${option.count == 1 ? '1 solicitud' : '${option.count} solicitudes'}',
                        child: Material(
                          color: option.filter == selected
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            key: Key('status-filter-${option.filter.name}'),
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(sheetContext).pop(
                              option.filter,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.label,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 16,
                                        fontWeight: option.filter == selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  _StatusCount(
                                    count: option.count,
                                    isSelected: option.filter == selected,
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox.square(
                                    dimension: AppIconSize.action,
                                    child: option.filter == selected
                                        ? const AppLineIcon(
                                            AppIcons.selected,
                                            size: AppIconSize.action,
                                            color: AppColors.primary,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
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
      ),
    );

    if (choice != null && choice != selected) onChanged(choice);
  }
}

class _StatusCount extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _StatusCount({required this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.hankenGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
