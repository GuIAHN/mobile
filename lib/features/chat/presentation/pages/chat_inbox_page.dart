import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
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
  _StatusFilter _statusFilter = _StatusFilter.all;
  bool _initializedProviderFilter = false;

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
        return threads.where((t) => t.matchState == 'PENDING').toList();
      case _StatusFilter.inquiring:
        return threads.where((t) => t.matchState == 'INQUIRING').toList();
      case _StatusFilter.declined:
        return threads.where((t) => t.matchState == 'DECLINED').toList();
      case _StatusFilter.quoted:
        return isStore
            ? threads.where((t) => t.matchState == 'QUOTED').toList()
            : threads
                .where(
                    (t) => t.totalOffersCount > 0 || t.bestOfferPrice != null)
                .toList();
      case _StatusFilter.bought:
        return threads
            .where((t) => isStore
                ? t.offerStatus == 'BOUGHT'
                : t.bestOfferStatus == 'BOUGHT' ||
                    t.bestOfferStatus == 'DELIVERED' ||
                    t.bestOfferStatus == 'CANCELLED')
            .toList();
      case _StatusFilter.delivered:
        return threads.where((t) => t.offerStatus == 'DELIVERED').toList();
      case _StatusFilter.cancelled:
        return threads
            .where((t) => isStore
                ? t.offerStatus == 'CANCELLED'
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
          allCount: 0,
          activeCount: 0,
          closedCount: 0,
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
          allCount: 0,
          activeCount: 0,
          closedCount: 0,
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
    final allCount = counts['all'] ?? searchFiltered.length;
    final activeCount = counts['open'] ??
        searchFiltered.where((t) => t.isOpen && !t.isExpired).length;
    final closedCount =
        counts['closed'] ?? (searchFiltered.length - activeCount);
    final pendingCount = counts['pending'] ??
        searchFiltered.where((t) => t.matchState == 'PENDING').length;
    final inquiringCount = counts['inquiring'] ??
        searchFiltered.where((t) => t.matchState == 'INQUIRING').length;
    final declinedCount = counts['declined'] ??
        searchFiltered.where((t) => t.matchState == 'DECLINED').length;
    final quotedCount = counts['quoted'] ??
        counts['withOffer'] ??
        searchFiltered
            .where((t) => isProvider
                ? t.hasOffer
                : t.totalOffersCount > 0 || t.bestOfferPrice != null)
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
    final discardedCount = counts['discarded'] ??
        searchFiltered.where((t) => t.offerStatus == 'DISCARDED').length;
    final visible = _applyStatus(searchFiltered, isProvider);

    return Column(
      children: [
        _buildHeader(
          isProvider: isProvider,
          isLoading: false,
          allCount: allCount,
          activeCount: activeCount,
          closedCount: closedCount,
          pendingCount: pendingCount,
          inquiringCount: inquiringCount,
          declinedCount: declinedCount,
          quotedCount: quotedCount,
          boughtCount: boughtCount,
          deliveredCount: deliveredCount,
          cancelledCount: cancelledCount,
          discardedCount: discardedCount,
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
    required int allCount,
    required int activeCount,
    required int closedCount,
    int pendingCount = 0,
    int inquiringCount = 0,
    int declinedCount = 0,
    int quotedCount = 0,
    int boughtCount = 0,
    int deliveredCount = 0,
    int cancelledCount = 0,
    int discardedCount = 0,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _StatusFilterChips(
                isProvider: isProvider,
                selected: _statusFilter,
                allCount: allCount,
                activeCount: activeCount,
                closedCount: closedCount,
                pendingCount: pendingCount,
                inquiringCount: inquiringCount,
                declinedCount: declinedCount,
                quotedCount: quotedCount,
                boughtCount: boughtCount,
                deliveredCount: deliveredCount,
                cancelledCount: cancelledCount,
                discardedCount: discardedCount,
                onChanged: (f) {
                  setState(() => _statusFilter = f);
                  final param = _mapFilterToParam(f, isProvider);
                  if (isProvider) {
                    ref.read(storeStatusFilterProvider.notifier).state = param;
                  } else {
                    ref.read(consumerStatusFilterProvider.notifier).state =
                        param;
                  }
                },
              ),
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

/// Fila de chips segmentados para filtrar por estado (Todas / Activas / Cerradas),
/// con contador por segmento. Patrón estándar para listas activas-vs-pasadas.
class _StatusFilterChips extends StatelessWidget {
  final bool isProvider;
  final _StatusFilter selected;
  final int allCount;
  final int activeCount;
  final int closedCount;
  final int pendingCount;
  final int inquiringCount;
  final int declinedCount;
  final int quotedCount;
  final int boughtCount;
  final int deliveredCount;
  final int cancelledCount;
  final int discardedCount;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusFilterChips({
    this.isProvider = false,
    required this.selected,
    required this.allCount,
    required this.activeCount,
    required this.closedCount,
    this.pendingCount = 0,
    this.inquiringCount = 0,
    this.declinedCount = 0,
    this.quotedCount = 0,
    this.boughtCount = 0,
    this.deliveredCount = 0,
    this.cancelledCount = 0,
    this.discardedCount = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isProvider) {
      return Row(
        children: [
          _StatusChip(
            label: 'Pendientes',
            count: pendingCount,
            isSelected: selected == _StatusFilter.pending,
            onTap: () => onChanged(_StatusFilter.pending),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Consultas',
            count: inquiringCount,
            isSelected: selected == _StatusFilter.inquiring,
            onTap: () => onChanged(_StatusFilter.inquiring),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Declinadas',
            count: declinedCount,
            isSelected: selected == _StatusFilter.declined,
            onTap: () => onChanged(_StatusFilter.declined),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Cotizadas',
            count: quotedCount,
            isSelected: selected == _StatusFilter.quoted,
            onTap: () => onChanged(_StatusFilter.quoted),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Vendidas',
            count: boughtCount,
            isSelected: selected == _StatusFilter.bought,
            onTap: () => onChanged(_StatusFilter.bought),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Entregadas',
            count: deliveredCount,
            isSelected: selected == _StatusFilter.delivered,
            onTap: () => onChanged(_StatusFilter.delivered),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Canceladas',
            count: cancelledCount,
            isSelected: selected == _StatusFilter.cancelled,
            onTap: () => onChanged(_StatusFilter.cancelled),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Descartadas',
            count: discardedCount,
            isSelected: selected == _StatusFilter.discarded,
            onTap: () => onChanged(_StatusFilter.discarded),
          ),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'Todas',
            count: allCount,
            isSelected: selected == _StatusFilter.all,
            onTap: () => onChanged(_StatusFilter.all),
          ),
        ],
      );
    }

    return Row(
      children: [
        _StatusChip(
          label: 'Todas',
          count: allCount,
          isSelected: selected == _StatusFilter.all,
          onTap: () => onChanged(_StatusFilter.all),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'Activas',
          count: activeCount,
          isSelected: selected == _StatusFilter.active,
          onTap: () => onChanged(_StatusFilter.active),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'Con ofertas',
          count: quotedCount,
          isSelected: selected == _StatusFilter.quoted,
          onTap: () => onChanged(_StatusFilter.quoted),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'Compradas',
          count: boughtCount,
          isSelected: selected == _StatusFilter.bought,
          onTap: () => onChanged(_StatusFilter.bought),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'Canceladas',
          count: cancelledCount,
          isSelected: selected == _StatusFilter.cancelled,
          onTap: () => onChanged(_StatusFilter.cancelled),
        ),
        const SizedBox(width: 8),
        _StatusChip(
          label: 'Cerradas',
          count: closedCount,
          isSelected: selected == _StatusFilter.closed,
          onTap: () => onChanged(_StatusFilter.closed),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.grey100,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
