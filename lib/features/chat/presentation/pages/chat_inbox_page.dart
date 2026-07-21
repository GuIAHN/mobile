import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../providers/chat_providers.dart';
import '../../domain/entities/chat_thread.dart';
import '../widgets/chat_thread_card.dart';
import '../widgets/store_chat_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

/// Filtro por estado de la solicitud/oferta.
enum _StatusFilter { all, active, closed, unquoted, quoted, bought }

class ChatInboxPage extends ConsumerStatefulWidget {
  const ChatInboxPage({super.key});

  @override
  ConsumerState<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends ConsumerState<ChatInboxPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _statusFilter = _StatusFilter.all;

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
          (t.clientName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// Filtro por estado.
  List<ChatThread> _applyStatus(List<ChatThread> threads, bool isProvider) {
    switch (_statusFilter) {
      case _StatusFilter.all:
        return threads;
      case _StatusFilter.active:
        return threads.where((t) => t.isOpen).toList();
      case _StatusFilter.closed:
        return threads.where((t) => !t.isOpen).toList();
      case _StatusFilter.unquoted:
        return threads.where((t) => !t.hasOffer).toList();
      case _StatusFilter.quoted:
        return threads.where((t) => t.hasOffer && t.offerStatus != 'BOUGHT').toList();
      case _StatusFilter.bought:
        return threads.where((t) => t.offerStatus == 'BOUGHT').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadsAsync = ref.watch(chatThreadsProvider);
    final myConversationsAsync = ref.watch(myConversationsProvider);
    final currentRole = ref.watch(currentRoleProvider);
    final isProvider = currentRole.isProvider;

    if (!isProvider) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: threadsAsync.when(
            loading: () => _buildLoadingState(isProvider),
            error: (err, _) => _buildErrorState(err.toString(), isProvider),
            data: (threads) => _buildThreadsList(threads, isProvider),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          toolbarHeight: 0,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.hankenGrotesk(fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                GoogleFonts.hankenGrotesk(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Solicitudes'),
              Tab(text: 'Mis Chats'),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              // Tab 1: Solicitudes (Search Requests)
              threadsAsync.when(
                loading: () => _buildLoadingState(isProvider),
                error: (err, _) => _buildErrorState(err.toString(), isProvider),
                data: (threads) => _buildThreadsList(threads, isProvider),
              ),
              // Tab 2: Mis Chats (Conversations)
              myConversationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (conversations) {
                  final filtered = conversations.where((c) {
                    if (_query.trim().isEmpty) return true;
                    final q = _query.trim().toLowerCase();
                    return c.participantName.toLowerCase().contains(q) ||
                        (c.spareBrand?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => ref.refresh(myConversationsProvider.future),
                      color: AppColors.primary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          EmptyState(
                            title: _query.isNotEmpty ? 'Sin resultados' : 'Sin chats activos',
                            subtitle: _query.isNotEmpty
                                ? 'No encontramos chats para "$_query".'
                                : 'Aún no tienes conversaciones iniciadas.',
                            icon: Icons.chat_bubble_outline_rounded,
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.refresh(myConversationsProvider.future),
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final conv = filtered[index];
                        return StaggeredEntrance(
                          index: index,
                          child: StoreChatCard(
                            conversation: conv,
                            onTap: () {
                              context.push('/chats/${conv.threadId}/${conv.id}');
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: const [
              ThreadCardSkeleton(),
              ThreadCardSkeleton(),
              ThreadCardSkeleton(),
              ThreadCardSkeleton(),
            ],
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
              'Error al cargar ofertas: $err',
              style: GoogleFonts.hankenGrotesk(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreadsList(List<ChatThread> threads, bool isProvider) {
    final searchFiltered = _applySearch(threads);
    final activeCount = searchFiltered.where((t) => t.isOpen).length;
    final closedCount = searchFiltered.length - activeCount;
    final unquotedCount = searchFiltered.where((t) => !t.hasOffer).length;
    final quotedCount = searchFiltered.where((t) => t.hasOffer && t.offerStatus != 'BOUGHT').length;
    final boughtCount = searchFiltered.where((t) => t.offerStatus == 'BOUGHT').length;
    final visible = _applyStatus(searchFiltered, isProvider);

    return Column(
      children: [
        _buildHeader(
          isProvider: isProvider,
          isLoading: false,
          allCount: searchFiltered.length,
          activeCount: activeCount,
          closedCount: closedCount,
          unquotedCount: unquotedCount,
          quotedCount: quotedCount,
          boughtCount: boughtCount,
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
        title: isProvider ? 'Sin solicitudes' : 'Aún no tienes ofertas',
        subtitle: isProvider
            ? 'No hay solicitudes activas para cotizar en este momento.'
            : 'Cuando solicites un repuesto o servicio, las ofertas de las tiendas aparecerán aquí.',
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
        onRefresh: () => ref.refresh(chatThreadsProvider.future),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          children: [
            const SizedBox(height: 80),
            emptyWidget,
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.refresh(chatThreadsProvider.future),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final thread = visible[index];
          return StaggeredEntrance(
            index: index,
            child: ChatThreadCard(
              thread: thread,
              showClientName: isProvider,
              onTap: () {
                context.push('/chats/${thread.id}');
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
    int unquotedCount = 0,
    int quotedCount = 0,
    int boughtCount = 0,
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
          // Identidad de la sección (solo consumer; el proveedor ya tiene TabBar).
          if (!isProvider) ...[
            Text(
              'Ofertas',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Compara las ofertas que recibes de las tiendas',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                unquotedCount: unquotedCount,
                quotedCount: quotedCount,
                boughtCount: boughtCount,
                onChanged: (f) => setState(() => _statusFilter = f),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isLoading, bool isProvider) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                isCollapsed: true,
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
  final int unquotedCount;
  final int quotedCount;
  final int boughtCount;
  final ValueChanged<_StatusFilter> onChanged;

  const _StatusFilterChips({
    this.isProvider = false,
    required this.selected,
    required this.allCount,
    required this.activeCount,
    required this.closedCount,
    this.unquotedCount = 0,
    this.quotedCount = 0,
    this.boughtCount = 0,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isProvider) {
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
            label: 'Sin cotizar',
            count: unquotedCount,
            isSelected: selected == _StatusFilter.unquoted,
            onTap: () => onChanged(_StatusFilter.unquoted),
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
