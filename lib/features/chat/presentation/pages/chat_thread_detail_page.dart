import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/router/route_names.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_conversation_card.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/staggered_entrance.dart';

enum _SortOption { recent, priceAsc, distanceAsc }

class ChatThreadDetailPage extends ConsumerStatefulWidget {
  final String threadId;

  const ChatThreadDetailPage({
    super.key,
    required this.threadId,
  });

  @override
  ConsumerState<ChatThreadDetailPage> createState() =>
      _ChatThreadDetailPageState();
}

class _ChatThreadDetailPageState extends ConsumerState<ChatThreadDetailPage> {
  _SortOption _currentSort = _SortOption.recent;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(chatConversationsProvider(widget.threadId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = ref.watch(currentRoleProvider);
    final isStore = currentRole == UserRole.store;
    final threadsAsync = ref.watch(
      isStore ? storeSalesRequestsProvider : consumerRequestsProvider,
    );
    final conversationsAsync =
        ref.watch(chatConversationsProvider(widget.threadId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Detalle de Solicitud',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            isStore ? storeSalesRequestsProvider : consumerRequestsProvider,
          );
          ref.invalidate(chatConversationsProvider(widget.threadId));
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Resumen de la Solicitud
            SliverToBoxAdapter(
              child: threadsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: OfferCardSkeleton(),
                ),
                error: (_, __) => const SizedBox.shrink(),
                data: (result) {
                  final threads = result.threads;
                  ChatThread? thread;
                  for (final candidate in threads) {
                    if (candidate.id == widget.threadId) {
                      thread = candidate;
                      break;
                    }
                  }
                  if (thread == null) {
                    return _MissingRequestSummary(isStore: isStore);
                  }
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: _RequestSummaryCard(
                      thread: thread,
                      isStore: isStore,
                    ),
                  );
                },
              ),
            ),

            // 2. Encabezado "X Ofertas Recibidas"
            SliverToBoxAdapter(
              child: conversationsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (conversations) {
                  if (conversations.isEmpty) return const SizedBox.shrink();
                  final quotedCount = conversations
                      .where((conversation) => conversation.hasFormalQuote)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    child: _OffersCountHeader(
                      quotedCount: quotedCount,
                      isStore: isStore,
                      currentSort: _currentSort,
                      onSortChanged: (val) {
                        setState(() {
                          _currentSort = val;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            // 3. Lista de Ofertas o Estado Vacío
            conversationsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildListDelegate(const [
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                  Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      child: OfferCardSkeleton()),
                ]),
              ),
              error: (err, _) {
                if (isStore) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error al cargar ofertas: $err',
                      style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                    ),
                  ),
                );
              },
              data: (conversations) {
                final sortedConversations = conversations.toList();
                sortedConversations.sort((a, b) {
                  switch (_currentSort) {
                    case _SortOption.recent:
                      return b.lastMessageAt.compareTo(a.lastMessageAt);
                    case _SortOption.priceAsc:
                      if (!a.hasQuote && !b.hasQuote) return 0;
                      if (!a.hasQuote) return 1;
                      if (!b.hasQuote) return -1;
                      final priceA = a.price ?? double.infinity;
                      final priceB = b.price ?? double.infinity;
                      return priceA.compareTo(priceB);
                    case _SortOption.distanceAsc:
                      final distA = a.distanceKm ?? double.infinity;
                      final distB = b.distanceKm ?? double.infinity;
                      return distA.compareTo(distB);
                  }
                });

                if (sortedConversations.isEmpty) {
                  if (isStore) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.forum_outlined,
                                size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Esperando ofertas',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Las tiendas de repuestos empezarán a cotizar y responder pronto. Te notificaremos.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conv = sortedConversations[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 6),
                        child: StaggeredEntrance(
                          key: ValueKey('offer-${conv.id}'),
                          index: index,
                          child: RealtimeChatConversationCard(
                            conversation: conv,
                            onTap: () async {
                              if (isStore) {
                                context.push(
                                  RouteNames.chatConversationPath(conv.id),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary)),
                                );

                                final repo = ref.read(chatRepositoryProvider);
                                final res =
                                    await repo.startChatFromOffer(conv.id);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                res.fold(
                                  (failure) {
                                    if (context.mounted) {
                                      context.showSnackBar(
                                          'Error al abrir chat: ${failure.message}',
                                          isError: true);
                                    }
                                  },
                                  (realConversationId) {
                                    if (context.mounted) {
                                      context.push(
                                        RouteNames.chatConversationPath(
                                          realConversationId,
                                        ),
                                      );
                                    }
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                    childCount: conversations.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _MissingRequestSummary extends StatelessWidget {
  const _MissingRequestSummary({required this.isStore});

  final bool isStore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Solicitud no disponible',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Puede haber cambiado de estado o no pertenecer al filtro actual.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => context.go(
                isStore ? RouteNames.sales : RouteNames.purchases,
              ),
              child: Text(isStore ? 'Volver a ventas' : 'Volver a compras'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends ConsumerStatefulWidget {
  final ChatThread thread;
  final bool isStore;

  const _RequestSummaryCard({
    required this.thread,
    required this.isStore,
  });

  @override
  ConsumerState<_RequestSummaryCard> createState() =>
      _RequestSummaryCardState();
}

class _RequestSummaryCardState extends ConsumerState<_RequestSummaryCard> {
  bool _isStartingChat = false;

  ChatThread get thread => widget.thread;
  bool get isStore => widget.isStore;

  Future<void> _startChat() async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);
    try {
      final quoteRes = await ref.read(createQuoteUseCaseProvider)(
        threadId: thread.id,
        searchMatchId: thread.searchMatchId,
      );
      if (!mounted) return;

      quoteRes.fold(
        (failure) => context.showSnackBar(
          'Error al iniciar chat: ${failure.message}',
          isError: true,
        ),
        (newConv) {
          ref.invalidate(chatConversationsProvider(thread.id));
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(myConversationsProvider);
          context.pushReplacement(
            RouteNames.chatConversationPath(newConv.id),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String partTypeLabel = 'Cualquiera';
    if (thread.partType != null) {
      if (thread.partType == 'ORIGINAL') {
        partTypeLabel = 'OEM';
      } else if (thread.partType == 'GENERIC') {
        partTypeLabel = 'Genérico';
      } else if (thread.partType == 'PERFORMANCE') {
        partTypeLabel = 'Alto rendimiento';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Hero Image Section
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(minHeight: 280),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primaryMuted,
            ),
            child: Stack(
              children: [
                // Background Image or Pattern
                Positioned.fill(
                  child: thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty
                      ? Image.network(
                          thread.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackBackground(),
                        )
                      : _buildFallbackBackground(),
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row (Badge)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'DATOS DE LA SOLICITUD',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (!thread.isOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                'CERRADA',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Bottom Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.subcategory ?? 'Repuesto',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.directions_car_rounded,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${thread.title} ${thread.vehicleYear != null ? "• ${thread.vehicleYear}" : ""}',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildGlassChip(
                                icon: Icons.extension_rounded,
                                label: partTypeLabel,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Additional Details
        if (thread.details != null && thread.details!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Detalles adicionales',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  thread.details!,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 3. Store Actions
        if (isStore) ...[
          const SizedBox(height: 24),
          if (thread.hasOffer)
            ElevatedButton.icon(
              onPressed: () {
                context.showSnackBar(
                  'Ya enviaste una cotización para esta solicitud.',
                );
              },
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
              label: Text(
                thread.offerPrice != null
                    ? 'COTIZACIÓN ENVIADA (\$${thread.offerPrice!.toStringAsFixed(2)})'
                    : 'COTIZACIÓN ENVIADA',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: _isStartingChat ? null : _startChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              child: _isStartingChat
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'INICIAR CHAT CON EL CLIENTE',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.inventory_2_rounded,
            size: 80, color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildGlassChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _OffersCountHeader extends StatelessWidget {
  final int quotedCount;
  final bool isStore;
  final _SortOption? currentSort;
  final ValueChanged<_SortOption>? onSortChanged;

  const _OffersCountHeader({
    required this.quotedCount,
    required this.isStore,
    this.currentSort,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!isStore && currentSort != null && onSortChanged != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, top: 4),
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildSortButton(),
        ),
      );
    }

    final label = isStore
        ? (quotedCount == 1 ? '1 cotización' : '$quotedCount cotizaciones')
        : (quotedCount == 1
            ? '1 cotización recibida'
            : '$quotedCount cotizaciones recibidas');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    String sortLabel;
    IconData sortIcon;
    switch (currentSort!) {
      case _SortOption.recent:
        sortLabel = 'Recientes';
        sortIcon = AppIcons.time;
        break;
      case _SortOption.priceAsc:
        sortLabel = 'Precio';
        sortIcon = AppIcons.price;
        break;
      case _SortOption.distanceAsc:
        sortLabel = 'Distancia';
        sortIcon = AppIcons.location;
        break;
    }

    return PopupMenuButton<_SortOption>(
      onSelected: onSortChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      position: PopupMenuPosition.under,
      child: Container(
        key: const Key('conversation-sort-filter'),
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLineIcon(
              sortIcon,
              size: AppIconSize.action,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              sortLabel,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            const AppLineIcon(
              AppIcons.expand,
              size: AppIconSize.action,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildPopupItem(_SortOption.recent, 'Más recientes', AppIcons.time),
        _buildPopupItem(_SortOption.priceAsc, 'Menor precio', AppIcons.price),
        _buildPopupItem(
            _SortOption.distanceAsc, 'Más cercanos', AppIcons.location),
      ],
    );
  }

  PopupMenuItem<_SortOption> _buildPopupItem(
      _SortOption value, String text, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          AppLineIcon(
            icon,
            size: AppIconSize.action,
            color: currentSort == value
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight:
                  currentSort == value ? FontWeight.bold : FontWeight.w600,
              color: currentSort == value
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
