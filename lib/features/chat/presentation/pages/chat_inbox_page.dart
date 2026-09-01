import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_thread.dart';
import '../widgets/chat_thread_card.dart';
import '../widgets/consumer_thread_card.dart';
import '../../../../shared/layout/bottom_navigation_insets.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../../shared/widgets/status_filter_selector.dart';

/// Filtro por estado de la solicitud/oferta.
enum _StatusFilter {
  all,
  pending,
  inquiring,
  quoted,
  bought,
  delivered,
  cancelled,
}

enum RequestInboxMode { consumerRequests, storeRequests, storeSales }

extension on RequestInboxMode {
  bool get isStore => this != RequestInboxMode.consumerRequests;
  bool get showsSalesHistory => this == RequestInboxMode.storeSales;
}

/// Bandeja reutilizada exclusivamente por solicitudes y ventas.
/// Las conversaciones reales viven en [ConversationsInboxPage].
class RequestsInboxPage extends ConsumerStatefulWidget {
  final RequestInboxMode mode;

  const RequestsInboxPage({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<RequestsInboxPage> createState() => _RequestsInboxPageState();
}

class _RequestsInboxPageState extends ConsumerState<RequestsInboxPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    if (widget.mode.isStore) {
      _statusFilter = widget.mode.showsSalesHistory
          ? _StatusFilter.delivered
          : _StatusFilter.pending;
    }
  }

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
    return threads
        .where((thread) => _matchesFilter(thread, _statusFilter, isStore))
        .toList();
  }

  bool _matchesFilter(
    ChatThread thread,
    _StatusFilter filter,
    bool isStore,
  ) {
    switch (filter) {
      case _StatusFilter.all:
        return true;
      case _StatusFilter.pending:
        return !_isExpired(thread) &&
            (thread.matchState == 'PENDING' ||
                thread.matchState == 'INQUIRING');
      case _StatusFilter.inquiring:
        return isStore
            ? thread.matchState == 'INQUIRING'
            : thread.questionsCount > 0;
      case _StatusFilter.quoted:
        return isStore
            ? thread.matchState == 'QUOTED'
            : thread.bestOfferPrice != null;
      case _StatusFilter.bought:
        return isStore && thread.offerStatus == 'BOUGHT';
      case _StatusFilter.delivered:
        return thread.offerStatus == 'DELIVERED';
      case _StatusFilter.cancelled:
        return isStore
            ? thread.offerStatus == 'CANCELLED'
            : thread.bestOfferStatus == 'CANCELLED';
    }
  }

  String _mapFilterToParam(_StatusFilter filter, bool isProvider) {
    if (isProvider) {
      switch (filter) {
        case _StatusFilter.pending:
          return 'TO_ANSWER';
        case _StatusFilter.inquiring:
          return 'INQUIRING';
        case _StatusFilter.quoted:
          return 'QUOTED';
        case _StatusFilter.bought:
          return 'TO_DELIVER';
        case _StatusFilter.delivered:
          return 'DELIVERED';
        case _StatusFilter.cancelled:
          return 'CANCELLED';
        case _StatusFilter.all:
          return 'ALL';
      }
    } else {
      switch (filter) {
        case _StatusFilter.quoted:
          return 'WITH_OFFER';
        // El API de solicitudes expone questionsCount por solicitud. Para
        // "Con preguntas" traemos ALL y filtramos esa señal en la vista.
        case _StatusFilter.pending:
        case _StatusFilter.inquiring:
        case _StatusFilter.bought:
        case _StatusFilter.delivered:
        case _StatusFilter.cancelled:
        case _StatusFilter.all:
          return 'ALL';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStore = widget.mode.isStore;
    final threadsAsync = ref.watch(
      isStore
          ? storeRequestsByStatusProvider(
              _mapFilterToParam(_statusFilter, true),
            )
          : consumerRequestsProvider,
    );

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
      widget.mode.isStore
          ? storeRequestsByStatusProvider(
              _mapFilterToParam(_statusFilter, true),
            ).future
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
              bottomNavigationContentInset(context) + AppSpacing.xl2,
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
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLineIcon(
                    AppIcons.cloudError,
                    size: AppIconSize.hero,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  Text(
                    'No pudimos cargar las solicitudes',
                    style: AppTypography.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(err, style: AppTypography.bodySm),
                  const SizedBox(height: AppSpacing.xl2),
                  SizedBox(
                    height: AppSpacing.buttonHeightMd,
                    child: OutlinedButton.icon(
                      onPressed: _refreshRequests,
                      icon: const AppLineIcon(
                        AppIcons.retry,
                        size: AppIconSize.inline,
                      ),
                      label: const Text('Reintentar'),
                    ),
                  ),
                ],
              ),
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
        counts['toReceive'] ??
        searchFiltered.where((t) => t.isOpen && !t.isExpired).length;
    // El contador debe representar exactamente lo que puede abrirse desde
    // Pendientes. No usamos los conteos del servidor porque una respuesta
    // desactualizada podría seguir incluyendo solicitudes ya vencidas.
    final pendingCount = searchFiltered
        .where((thread) =>
            _matchesFilter(thread, _StatusFilter.pending, isProvider))
        .length;
    final quotedCount = counts['quoted'] ??
        counts['withOffer'] ??
        searchFiltered
            .where((thread) =>
                _matchesFilter(thread, _StatusFilter.quoted, isProvider))
            .length;
    final boughtCount = counts['bought'] ??
        searchFiltered
            .where((thread) =>
                _matchesFilter(thread, _StatusFilter.bought, isProvider))
            .length;
    final deliveredCount = counts['delivered'] ??
        searchFiltered
            .where((thread) =>
                _matchesFilter(thread, _StatusFilter.delivered, isProvider))
            .length;
    final cancelledCount = counts['cancelled'] ??
        searchFiltered
            .where((thread) =>
                _matchesFilter(thread, _StatusFilter.cancelled, isProvider))
            .length;
    final questionsCount =
        searchFiltered.where((thread) => thread.questionsCount > 0).length;
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
          questionsCount: questionsCount,
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
        icon: isProvider ? AppIcons.inbox : AppIcons.offer,
      );
    } else if (searchFiltered.isEmpty) {
      // La búsqueda por texto no arrojó resultados.
      emptyWidget = EmptyState(
        title: 'Sin resultados',
        subtitle: 'No encontramos nada para "$_query".',
        icon: AppIcons.searchEmpty,
      );
    } else if (visible.isEmpty) {
      // El filtro de estado dejó la lista vacía.
      emptyWidget = const EmptyState(
        title: 'Sin solicitudes en esta categoría',
        subtitle: 'No hay elementos para el filtro seleccionado por ahora.',
        icon: AppIcons.filter,
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
            bottom: bottomNavigationContentInset(context) + AppSpacing.xl2,
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
          bottomNavigationContentInset(context) + AppSpacing.xl2,
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
    int questionsCount = 0,
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
              showsSalesHistory: widget.mode.showsSalesHistory,
              selected: _statusFilter,
              activeCount: activeCount,
              pendingCount: pendingCount,
              quotedCount: quotedCount,
              boughtCount: boughtCount,
              deliveredCount: deliveredCount,
              cancelledCount: cancelledCount,
              questionsCount: questionsCount,
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
          const AppLineIcon(
            AppIcons.search,
            size: AppIconSize.action,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _searchController,
              enabled: !isLoading,
              onChanged: (val) => setState(() => _query = val),
              style: AppTypography.body,
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
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar búsqueda',
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.buttonHeightMd,
                height: AppSpacing.buttonHeightMd,
              ),
              icon: const AppLineIcon(
                AppIcons.close,
                size: AppIconSize.inline,
                color: AppColors.textSecondary,
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
  final bool showsSalesHistory;
  final _StatusFilter selected;
  final int activeCount;
  final int pendingCount;
  final int quotedCount;
  final int boughtCount;
  final int deliveredCount;
  final int cancelledCount;
  final int questionsCount;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusFilterSelector({
    this.isProvider = false,
    this.showsSalesHistory = false,
    required this.selected,
    required this.activeCount,
    this.pendingCount = 0,
    this.quotedCount = 0,
    this.boughtCount = 0,
    this.deliveredCount = 0,
    this.cancelledCount = 0,
    this.questionsCount = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = isProvider
        ? !showsSalesHistory
            ? <({String label, int count, _StatusFilter filter})>[
                (
                  label: 'Por responder',
                  count: pendingCount,
                  filter: _StatusFilter.pending,
                ),
                (
                  label: 'Cotizada',
                  count: quotedCount,
                  filter: _StatusFilter.quoted,
                ),
                (
                  label: 'Por entregar',
                  count: boughtCount,
                  filter: _StatusFilter.bought,
                ),
              ]
            : <({String label, int count, _StatusFilter filter})>[
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
              label: 'Todas',
              count: activeCount,
              filter: _StatusFilter.all,
            ),
            (
              label: 'Cotizadas',
              count: quotedCount,
              filter: _StatusFilter.quoted,
            ),
            (
              label: 'Con preguntas',
              count: questionsCount,
              filter: _StatusFilter.inquiring,
            ),
          ];
    return AppStatusFilterSelector<_StatusFilter>(
      controlKey: Key(
        isProvider
            ? !showsSalesHistory
                ? 'store-requests-filter-group'
                : 'store-sales-filter-group'
            : 'consumer-request-filter-group',
      ),
      selected: selected,
      options: [
        for (final option in options)
          StatusFilterOption(
            value: option.filter,
            label: option.label,
            count: option.count,
          ),
      ],
      optionKeyBuilder: (filter) => Key('status-filter-${filter.name}'),
      onChanged: onChanged,
    );
  }

  // ignore: unused_element
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
                  style: AppTypography.h2,
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
                                      style: AppTypography.body.copyWith(
                                        fontWeight: option.filter == selected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
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
        style: AppTypography.meta.copyWith(
          fontWeight: FontWeight.w800,
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}
