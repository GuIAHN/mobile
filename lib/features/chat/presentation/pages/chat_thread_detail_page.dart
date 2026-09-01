import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_typography.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            edgeOffset: MediaQuery.paddingOf(context).top,
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
                    loading: () => _RequestHeroSkeleton(
                      onBack: () => context.pop(),
                    ),
                    error: (_, __) => _RequestSummaryError(
                      onBack: () => context.pop(),
                      onRetry: () => ref.invalidate(
                        isStore
                            ? storeSalesRequestsProvider
                            : consumerRequestsProvider,
                      ),
                    ),
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
                        return _MissingRequestSummary(
                          isStore: isStore,
                          onBack: () => context.pop(),
                        );
                      }
                      return _RequestSummaryCard(
                        thread: thread,
                        isStore: isStore,
                        onBack: () => context.pop(),
                      );
                    },
                  ),
                ),

                // 2. Filtro y conteo, inmediatamente después de la cabecera.
                SliverToBoxAdapter(
                  child: conversationsAsync.when(
                    loading: () => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: _OffersCountHeader(
                        quotedCount: null,
                        isStore: isStore,
                        currentSort: isStore ? null : _currentSort,
                        onSortChanged: isStore
                            ? null
                            : (val) => setState(() => _currentSort = val),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (conversations) {
                      final quotedCount = conversations
                          .where((conversation) => conversation.hasFormalQuote)
                          .length;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
                    delegate: SliverChildListDelegate([
                      _motionAwareSkeleton(
                        context,
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          child: OfferCardSkeleton(),
                        ),
                      ),
                      _motionAwareSkeleton(
                        context,
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          child: OfferCardSkeleton(),
                        ),
                      ),
                      _motionAwareSkeleton(
                        context,
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                          child: OfferCardSkeleton(),
                        ),
                      ),
                    ]),
                  ),
                  error: (err, _) {
                    return SliverToBoxAdapter(
                      child: _OffersErrorState(
                        onRetry: () => ref.invalidate(
                          chatConversationsProvider(widget.threadId),
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
                      return SliverToBoxAdapter(
                        child: _OffersEmptyState(isStore: isStore),
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

                                    final repo =
                                        ref.read(chatRepositoryProvider);
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
                        childCount: sortedConversations.length,
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _motionAwareSkeleton(BuildContext context, Widget child) {
  return TickerMode(
    enabled: !MediaQuery.disableAnimationsOf(context),
    child: child,
  );
}

class _MissingRequestSummary extends StatelessWidget {
  const _MissingRequestSummary({
    required this.isStore,
    required this.onBack,
  });

  final bool isStore;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StandalonePageHeader(onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const AppLineIcon(
                  AppIcons.searchEmpty,
                  size: AppIconSize.feature,
                  color: AppColors.textSecondary,
                  semanticLabel: 'Solicitud no disponible',
                ),
                const SizedBox(height: 12),
                Text('Solicitud no disponible', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Puede haber cambiado de estado o no pertenecer al filtro actual.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(
                      isStore ? RouteNames.sales : RouteNames.purchases,
                    ),
                    child: Text(
                      isStore ? 'Volver a ventas' : 'Volver a compras',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestSummaryError extends StatelessWidget {
  const _RequestSummaryError({
    required this.onBack,
    required this.onRetry,
  });

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StandalonePageHeader(onBack: onBack),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const AppLineIcon(
                  AppIcons.connectivityError,
                  size: AppIconSize.feature,
                  color: AppColors.errorInk,
                  semanticLabel: 'Error de conexión',
                ),
                const SizedBox(height: 12),
                Text('No pudimos cargar la solicitud', style: AppTypography.h2),
                const SizedBox(height: 8),
                Text(
                  'Revisa tu conexión e inténtalo nuevamente.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const AppLineIcon(
                      AppIcons.retry,
                      size: AppIconSize.action,
                    ),
                    label: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StandalonePageHeader extends StatelessWidget {
  const _StandalonePageHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 8,
        24,
        4,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Volver',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: const AppLineIcon(
              AppIcons.back,
              size: AppIconSize.leading,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text('Detalle de solicitud', style: AppTypography.title),
          ),
        ],
      ),
    );
  }
}

class _RequestHeroSkeleton extends StatelessWidget {
  const _RequestHeroSkeleton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Semantics(
        label: 'Cargando detalle de solicitud',
        container: true,
        child: SizedBox(
          height: 360 + topInset,
          child: ColoredBox(
            color: AppColors.secondary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _motionAwareSkeleton(
                    context,
                    const SkeletonBox(
                      height: 360,
                      borderRadius: 0,
                      baseColor: AppColors.grey800,
                      highlightColor: AppColors.grey700,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, topInset + 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroTopBar(onBack: onBack),
                      const Spacer(),
                      const SkeletonBox(
                        width: 150,
                        height: 24,
                        borderRadius: 12,
                        baseColor: AppColors.grey700,
                        highlightColor: AppColors.grey600,
                      ),
                      const SizedBox(height: 14),
                      const SkeletonBox(
                        width: 250,
                        height: 30,
                        borderRadius: 8,
                        baseColor: AppColors.grey700,
                        highlightColor: AppColors.grey600,
                      ),
                      const SizedBox(height: 12),
                      const SkeletonBox(
                        width: 190,
                        height: 18,
                        borderRadius: 6,
                        baseColor: AppColors.grey700,
                        highlightColor: AppColors.grey600,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestSummaryCard extends ConsumerStatefulWidget {
  final ChatThread thread;
  final bool isStore;
  final VoidCallback onBack;

  const _RequestSummaryCard({
    required this.thread,
    required this.isStore,
    required this.onBack,
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

    final usesLargeText = MediaQuery.textScalerOf(context).scale(15) > 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final baseHeight = (constraints.maxWidth * 0.9).clamp(340.0, 420.0);
            final minHeight = baseHeight + (usesLargeText ? 104 : 0);

            final topInset = MediaQuery.paddingOf(context).top;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
              ),
              child: Semantics(
                container: true,
                label:
                    'Resumen de la solicitud de ${thread.subcategory ?? 'repuesto'}',
                child: Container(
                  key: const Key('request-photo-hero'),
                  width: double.infinity,
                  color: AppColors.secondary,
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      Positioned.fill(child: _buildHeroMedia(context)),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.58),
                                Colors.black.withValues(alpha: 0.16),
                                Colors.black.withValues(alpha: 0.9),
                              ],
                              stops: const [0, 0.42, 1],
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: minHeight + topInset),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding:
                                EdgeInsets.fromLTRB(12, topInset + 8, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _HeroTopBar(onBack: widget.onBack),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildHeroBadge(
                                            label: 'DATOS DE LA SOLICITUD',
                                          ),
                                          if (!thread.isOpen)
                                            _buildHeroBadge(
                                              label: 'CERRADA',
                                              color: AppColors.errorInk,
                                              borderColor: AppColors.errorInk,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        thread.subcategory ?? 'Repuesto',
                                        style: AppTypography.display.copyWith(
                                          color: AppColors.textOnPrimary,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black54,
                                              offset: Offset(0, 2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: AppLineIcon(
                                              AppIcons.vehicle,
                                              size: AppIconSize.action,
                                              color: AppColors.textOnPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${thread.title}${thread.vehicleYear != null ? ' · ${thread.vehicleYear}' : ''}',
                                              style:
                                                  AppTypography.body.copyWith(
                                                color: AppColors.textOnPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _buildGlassChip(
                                            icon: AppIcons.catalog,
                                            label: partTypeLabel,
                                          ),
                                        ],
                                      ),
                                      if (thread.details != null &&
                                          thread.details!
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 18),
                                        Container(
                                          padding:
                                              const EdgeInsets.only(top: 14),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.28),
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(top: 1),
                                                child: AppLineIcon(
                                                  AppIcons.info,
                                                  size: AppIconSize.inline,
                                                  color:
                                                      AppColors.textOnPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  thread.details!.trim(),
                                                  style: AppTypography.bodySm
                                                      .copyWith(
                                                    color:
                                                        AppColors.textOnPrimary,
                                                    height: 1.45,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
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
              ),
            );
          },
        ),

        // La acción de tienda conserva su jerarquía, fuera del hero para no
        // competir con la lectura de la solicitud.
        if (isStore) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: thread.hasOffer
                ? ElevatedButton.icon(
                    onPressed: () {
                      context.showSnackBar(
                        'Ya enviaste una cotización para esta solicitud.',
                      );
                    },
                    icon: const AppLineIcon(
                      AppIcons.success,
                      size: AppIconSize.action,
                      color: AppColors.textOnPrimary,
                    ),
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
                : ElevatedButton(
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
                              const AppLineIcon(
                                AppIcons.message,
                                size: AppIconSize.action,
                                color: AppColors.textOnPrimary,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'INICIAR CHAT CON EL CLIENTE',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroMedia(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final hasPhoto =
        thread.fotoUrl != null && thread.fotoUrl!.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildFallbackBackground(),
        if (hasPhoto)
          ExcludeSemantics(
            child: Image.network(
              thread.fotoUrl!,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackBackground() {
    return ColoredBox(
      color: AppColors.grey900,
      child: Opacity(
        opacity: 0.72,
        child: Image.asset(
          'assets/images/header_car.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          excludeFromSemantics: true,
        ),
      ),
    );
  }

  Widget _buildHeroBadge({
    required String label,
    Color color = const Color(0x52000000),
    Color borderColor = const Color(0x66FFFFFF),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: AppTypography.overline.copyWith(
          color: AppColors.textOnPrimary,
        ),
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
          AppLineIcon(
            icon,
            size: AppIconSize.inline,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTopBar extends StatelessWidget {
  const _HeroTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Volver',
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.38),
            foregroundColor: AppColors.textOnPrimary,
          ),
          icon: const AppLineIcon(
            AppIcons.back,
            size: AppIconSize.leading,
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 13),
            child: Text(
              'Detalle de solicitud',
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(
                color: AppColors.textOnPrimary,
                shadows: const [
                  Shadow(color: Colors.black54, blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 56),
      ],
    );
  }
}

class _OffersErrorState extends StatelessWidget {
  const _OffersErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const AppLineIcon(
              AppIcons.connectivityError,
              size: AppIconSize.feature,
              color: AppColors.errorInk,
              semanticLabel: 'Error al cargar ofertas',
            ),
            const SizedBox(height: 12),
            Text('No pudimos cargar las ofertas', style: AppTypography.title),
            const SizedBox(height: 6),
            Text(
              'Revisa tu conexión y vuelve a intentarlo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const AppLineIcon(
                  AppIcons.retry,
                  size: AppIconSize.action,
                ),
                label: const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffersEmptyState extends StatelessWidget {
  const _OffersEmptyState({required this.isStore});

  final bool isStore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLineIcon(
            AppIcons.inbox,
            size: AppIconSize.feature,
            color: AppColors.primary,
            semanticLabel: 'Sin ofertas',
          ),
          const SizedBox(height: 16),
          Text(
            isStore ? 'Sin conversaciones todavía' : 'Esperando ofertas',
            textAlign: TextAlign.center,
            style: AppTypography.title,
          ),
          const SizedBox(height: 8),
          Text(
            isStore
                ? 'Inicia el chat para consultar al cliente o preparar tu cotización.'
                : 'Las tiendas empezarán a cotizar pronto. Te notificaremos cuando llegue una oferta.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm,
          ),
        ],
      ),
    );
  }
}

class _OffersCountHeader extends StatelessWidget {
  final int? quotedCount;
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
    final canSort = !isStore && currentSort != null && onSortChanged != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 4),
      child: canSort
          ? _buildSegmentedSortControl(context)
          : _buildSectionTitle(context),
    );
  }

  Widget _buildSectionTitle(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Cotizaciones',
              style: AppTypography.h2,
            ),
          ),
          const SizedBox(width: 8),
          if (quotedCount == null)
            _motionAwareSkeleton(
              context,
              const SkeletonBox(width: 30, height: 24, borderRadius: 12),
            )
          else
            Container(
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$quotedCount',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSegmentedSortControl(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final segmentTextScale = textScale > 1.3 ? 1.3 : textScale;
    const options = [
      (_SortOption.recent, 'Recientes', AppIcons.time),
      (_SortOption.priceAsc, 'Mejor precio', AppIcons.price),
      (_SortOption.distanceAsc, 'Más cercanos', AppIcons.location),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalSegments =
            constraints.maxWidth < 390 || textScale > 1.35;

        return Container(
          key: const Key('conversation-sort-filter'),
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: SizedBox(
            height: useVerticalSegments ? (textScale > 1.35 ? 120 : 84) : 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final option in options)
                  Expanded(
                    child: _buildSortSegment(
                      context: context,
                      option: option.$1,
                      label: option.$2,
                      icon: option.$3,
                      useVerticalLayout: useVerticalSegments,
                      reduceMotion: reduceMotion,
                      textScale: segmentTextScale,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortSegment({
    required BuildContext context,
    required _SortOption option,
    required String label,
    required IconData icon,
    required bool useVerticalLayout,
    required bool reduceMotion,
    required double textScale,
  }) {
    final isSelected = currentSort == option;
    final foreground =
        isSelected ? AppColors.textPrimary : AppColors.textSecondary;
    final content = useVerticalLayout
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLineIcon(icon, size: AppIconSize.action, color: foreground),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(color: foreground),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLineIcon(icon, size: AppIconSize.inline, color: foreground),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.label.copyWith(color: foreground),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Ordenar ofertas por $label',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSelected ? null : () => onSortChanged?.call(option),
            borderRadius: BorderRadius.circular(13),
            child: AnimatedContainer(
              key: ValueKey(
                'conversation-sort-${option.name}-${isSelected ? 'selected' : 'idle'}',
              ),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border:
                    isSelected ? Border.all(color: AppColors.grey200) : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [],
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
