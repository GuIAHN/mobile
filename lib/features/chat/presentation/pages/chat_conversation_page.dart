import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/error/failures.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_message_composer.dart';
import '../widgets/active_offer_header_card.dart';
import '../widgets/confirm_purchase_dialog.dart';
import '../widgets/cancel_purchase_dialog.dart';
import '../widgets/non_delivery_dialog.dart';
import '../../domain/entities/chat_conversation.dart';
import '../widgets/moderation_blocked_dialog.dart';
import '../widgets/store_contact_sheet.dart';
import '../widgets/quote_input_dialog.dart';
import '../widgets/decline_match_dialog.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../../shared/utils/subcategory_presentation.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatConversationPage({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatConversationPage> createState() =>
      _ChatConversationPageState();
}

class _ChatConversationPageState extends ConsumerState<ChatConversationPage> {
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _canSend = false;
  bool _isSending = false;
  bool _isQuoting = false;
  bool _isDeclining = false;
  bool _declinedLocally = false;
  bool _isCancelling = false;
  bool _isDelivering = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);
    _messageFocusNode.addListener(_handleFocusChange);
    // Mark as read in the background
    Future.microtask(() async {
      await ref.read(markAsReadUseCaseProvider).call(widget.conversationId);
      if (mounted) {
        ref.invalidate(myConversationsProvider);
      }
    });
  }

  void _handleTextChange() {
    final canSend = _messageController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageFocusNode.removeListener(_handleFocusChange);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    final notifier =
        ref.read(chatMessagesProvider(widget.conversationId).notifier);

    try {
      await notifier.sendMessage(text);
      _messageController.clear();
      if (mounted) setState(() => _isSending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        final message = e is RealtimeRequestException
            ? e.message
            : e.toString().replaceAll('Exception:', '').trim();
        // Moderation rejections get a dedicated dialog (deliberate policy
        // violation) instead of the generic notification used for transient
        // errors (disconnects, not-a-participant, etc.).
        if (e is RealtimeRequestException && e.code == 'CONTENT_REJECTED') {
          ModerationBlockedDialog.show(context);
        } else {
          context.showSnackBar(message, isError: true);
        }
      }
    }
  }

  Future<void> _quoteFromChat(String offerId, String requestTitle) async {
    final result = await QuoteInputDialog.show(context, requestTitle);
    if (result == null || !mounted) return;

    setState(() => _isQuoting = true);
    try {
      final useCase = ref.read(quoteOfferUseCaseProvider);
      final res = await useCase(
        offerId: offerId,
        price: result['price'] as double,
        updateDeliveryCost: result['updateDeliveryCost'] as bool? ?? false,
        deliveryCost: result['deliveryCost'] as double?,
        brand: result['brand'] as String?,
        photoPath: result['photoPath'] as String?,
      );
      res.fold(
        (failure) {
          if (mounted) {
            context.showSnackBar(
              'Error al cotizar: ${failure.message}',
              isError: true,
            );
          }
        },
        (_) {
          ref.invalidate(
              chatConversationDetailsProvider(widget.conversationId));
          ref.invalidate(myConversationsProvider);
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(storeRequestsByStatusProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isQuoting = false);
    }
  }

  Future<void> _cancelPurchase(
    ChatConversation details, {
    required bool isStore,
  }) async {
    if (_isCancelling || details.offerId == null) return;

    if (isStore) {
      final selection = await NonDeliveryDialog.show(context);
      if (selection == null || !mounted) return;
      setState(() => _isCancelling = true);
      try {
        final result = await ref.read(cancelSaleByStoreUseCaseProvider)(
          details.offerId!,
          reasonCode: selection.reasonCode,
          note: selection.note,
        );
        _handleCancellationResult(result);
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
      return;
    } else {
      final confirmation = await CancelPurchaseDialog.show(context);
      if (confirmation == null || !mounted) return;
      setState(() => _isCancelling = true);
      try {
        final result = await ref.read(cancelOfferUseCaseProvider)(
          details.offerId!,
          reason: confirmation.reason,
        );
        _handleCancellationResult(result);
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  void _handleCancellationResult(Either<Failure, void> result) {
    result.fold(
      (failure) {
        if (mounted) {
          context.showSnackBar(
            failure.code == 409
                ? 'La compra cambió de estado. Actualizamos la información.'
                : 'No se pudo cancelar: ${failure.message}',
            isError: true,
          );
        }
      },
      (_) {},
    );
    ref.invalidate(chatConversationDetailsProvider(widget.conversationId));
    ref.invalidate(myConversationsProvider);
    ref.invalidate(consumerRequestsProvider);
    ref.invalidate(storeSalesRequestsProvider);
    ref.invalidate(storeRequestsByStatusProvider);
    ref.invalidate(storeDashboardProvider);
  }

  Future<void> _deliverOffer(ChatConversation details) async {
    if (_isDelivering || details.offerId == null) return;

    setState(() => _isDelivering = true);
    try {
      final result = await ref.read(deliverOfferUseCaseProvider)(
        details.offerId!,
      );

      result.fold(
        (failure) {
          if (mounted) {
            context.showSnackBar(
              'Error: ${failure.message}',
              isError: true,
            );
          }
        },
        (_) {
          ref.invalidate(
            chatConversationDetailsProvider(widget.conversationId),
          );
          ref.invalidate(myConversationsProvider);
          ref.invalidate(storeSalesRequestsProvider);
          ref.invalidate(storeRequestsByStatusProvider);
          ref.invalidate(storeDashboardProvider);
        },
      );
    } finally {
      if (mounted) setState(() => _isDelivering = false);
    }
  }

  Future<void> _declineFromChat(ChatConversation details) async {
    final searchMatchId = details.searchMatchId;
    if (searchMatchId == null || _isDeclining) return;

    final reason = await DeclineMatchDialog.show(context);
    if (reason == null || !mounted) return;

    setState(() => _isDeclining = true);
    try {
      final result = await ref.read(declineMatchUseCaseProvider)(
        searchMatchId,
        reason,
      );
      var succeeded = false;
      result.fold(
        (failure) {
          if (mounted) {
            context.showSnackBar(
              'No se pudo marcar como no atendida: ${failure.message}',
              isError: true,
            );
          }
        },
        (_) => succeeded = true,
      );
      if (!succeeded || !mounted) return;

      setState(() => _declinedLocally = true);
      ref.invalidate(chatConversationDetailsProvider(widget.conversationId));
      ref.invalidate(myConversationsProvider);
      ref.invalidate(storeSalesRequestsProvider);
      ref.invalidate(storeRequestsByStatusProvider);
      ref.invalidate(storeDashboardProvider);
      await ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .loadMessages();
      if (mounted) {
        context.showSnackBar('Marcaste esta solicitud como no atendida.');
      }
    } finally {
      if (mounted) setState(() => _isDeclining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentRole = ref.watch(currentRoleProvider);
    final isStore = currentRole == UserRole.store;

    // Scroll to bottom when data initially loads or updates
    ref.listen(chatMessagesProvider(widget.conversationId), (prev, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final detailsAsync =
        ref.watch(chatConversationDetailsProvider(widget.conversationId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: detailsAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Chat'),
          data: (details) {
            final hideStoreIdentity = !isStore && !details.revealsStoreIdentity;
            final avatarUrl =
                hideStoreIdentity ? null : details.participantAvatarUrl;
            return Row(
              children: [
                Semantics(
                  image: true,
                  label: hideStoreIdentity
                      ? 'Perfil genérico de la tienda'
                      : 'Foto de perfil de ${details.participantName}',
                  child: Container(
                    key: hideStoreIdentity
                        ? const Key('generic-store-avatar')
                        : const Key('participant-avatar'),
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.antiAlias,
                    decoration: const BoxDecoration(
                      color: AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const AppLineIcon(
                              AppIcons.account,
                              size: AppIconSize.action,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : AppLineIcon(
                            hideStoreIdentity
                                ? AppIcons.store
                                : AppIcons.account,
                            size: AppIconSize.action,
                            color: AppColors.textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.participantName,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isStore ? 'Comprador' : 'Tienda',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Acciones de consulta (tienda, oferta en INQUIRY) ─────────────
            // En una sola fila para conservar el espacio vertical del chat.
            // Se mantiene lejos del compositor para evitar toques accidentales.
            if (isStore &&
                detailsAsync.valueOrNull?.isInquiry == true &&
                detailsAsync.valueOrNull?.offerId != null &&
                detailsAsync.valueOrNull?.declinedAt == null &&
                !_declinedLocally)
              Container(
                key: const Key('inquiry-actions-bar'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                color: Colors.white,
                child: Row(
                  children: [
                    if (detailsAsync.valueOrNull!.searchMatchId != null)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('decline-inquiry-button'),
                            onPressed: _isQuoting || _isDeclining
                                ? null
                                : () => _declineFromChat(
                                      detailsAsync.valueOrNull!,
                                    ),
                            icon: _isDeclining
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textSecondary,
                                    ),
                                  )
                                : AppLineIcon(
                                    AppIcons.declined,
                                    size: AppIconSize.inline,
                                    color: _isQuoting
                                        ? AppColors.textDisabled
                                        : AppColors.textSecondary,
                                  ),
                            label: Text(
                              _isDeclining ? 'Declinando…' : 'Declinar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              disabledForegroundColor: AppColors.textDisabled,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              side: const BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          key: const Key('quote-inquiry-button'),
                          onPressed: _isQuoting || _isDeclining
                              ? null
                              : () => _quoteFromChat(
                                    detailsAsync.valueOrNull!.offerId!,
                                    presentSubcategoryPath(
                                      categoryName: detailsAsync
                                          .valueOrNull!.categoryName,
                                      subcategoryName: detailsAsync
                                          .valueOrNull!.subcategoryName,
                                      isCatchAll: detailsAsync
                                          .valueOrNull!.subcategoryIsCatchAll,
                                      audience:
                                          SubcategoryPresentationAudience.store,
                                      fallback: 'la solicitud',
                                    ),
                                  ),
                          icon: _isQuoting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : AppLineIcon(
                                  AppIcons.offer,
                                  size: AppIconSize.inline,
                                  color: _isDeclining
                                      ? AppColors.textDisabled
                                      : AppColors.primary,
                                ),
                          label: Text(
                            _isQuoting ? 'Cotizando…' : 'Cotizar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            disabledForegroundColor: AppColors.textDisabled,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            side: BorderSide(
                              color: _isQuoting || _isDeclining
                                  ? AppColors.border
                                  : AppColors.primary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Active Offer Header ─────────────────────────────────────────
            if (detailsAsync.valueOrNull != null &&
                detailsAsync.valueOrNull!.hasQuote)
              ActiveOfferHeaderCard(
                details: detailsAsync.valueOrNull!,
                isStore: isStore,
                isCancelling: _isCancelling,
                isDelivering: _isDelivering,
                onCancelPressed: () => _cancelPurchase(
                  detailsAsync.valueOrNull!,
                  isStore: isStore,
                ),
                onBuyPressed: () async {
                  final details = detailsAsync.valueOrNull!;
                  final confirmed = await ConfirmPurchaseDialog.show(
                    context,
                    details: details,
                  );
                  if (confirmed != true) return;

                  if (!context.mounted) return;
                  final usecase = ref.read(buyOfferUseCaseProvider);
                  final result = await usecase(details.offerId!);

                  result.fold(
                    (f) {
                      if (context.mounted) {
                        context.showSnackBar(
                          'Error: ${f.message}',
                          isError: true,
                        );
                      }
                    },
                    (_) async {
                      ref.invalidate(chatConversationDetailsProvider(
                          widget.conversationId));
                      ref.invalidate(myConversationsProvider);
                      ref.invalidate(consumerRequestsProvider);

                      // Direct fetch for fresh details without awaiting Riverpod future rebuild loop
                      final repo = ref.read(chatRepositoryProvider);
                      final updatedRes = await repo
                          .getConversationDetails(widget.conversationId);
                      final freshDetails =
                          updatedRes.fold((_) => details, (d) => d);

                      if (!context.mounted) return;
                      await StoreContactSheet.show(
                        context,
                        details: freshDetails,
                        isPostPurchase: true,
                      );
                    },
                  );
                },
                onDeliverPressed: () =>
                    _deliverOffer(detailsAsync.valueOrNull!),
                onReviewPressed: () async {
                  final details = detailsAsync.valueOrNull!;
                  final res = await context.push<bool>(
                    RouteNames.reviewEditorPath(
                      targetId: details.storeUserId,
                      conversationId: widget.conversationId,
                      providerName: details.participantName,
                    ),
                  );
                  if (res == true && mounted) {
                    ref.invalidate(
                        chatConversationDetailsProvider(widget.conversationId));
                    ref.invalidate(myConversationsProvider);
                  }
                },
              ),

            // ── Messages feed ─────────────────────────────────────────────
            Expanded(
              child: messagesAsync.when(
                loading: () => ListView(
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  children: const [
                    MessageBubbleSkeleton(),
                    MessageBubbleSkeleton(alignRight: true),
                    MessageBubbleSkeleton(),
                  ],
                ),
                error: (_, __) => _ChatMessagesError(
                  onRetry: () => ref.invalidate(
                    chatMessagesProvider(widget.conversationId),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return _EmptyChatState(
                      participantName:
                          detailsAsync.valueOrNull?.participantName,
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ChatMessageBubble(message: message);
                    },
                  );
                },
              ),
            ),

            // Cápsula de escritura + acción circular, como un chat móvil.
            ChatMessageComposer(
              controller: _messageController,
              focusNode: _messageFocusNode,
              canSend: _canSend,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final String? participantName;

  const _EmptyChatState({this.participantName});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const verticalPadding = 48.0;
        final minContentHeight = constraints.maxHeight > verticalPadding
            ? constraints.maxHeight - verticalPadding
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppLineIcon(
                    AppIcons.message,
                    size: AppIconSize.feature,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Inicia la conversación',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    participantName == null
                        ? 'Escribe un mensaje para conversar sobre esta oferta.'
                        : 'Escribe a $participantName para conversar sobre esta oferta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessagesError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ChatMessagesError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLineIcon(
              AppIcons.connectivityError,
              size: AppIconSize.feature,
              color: AppColors.errorInk,
            ),
            const SizedBox(height: 12),
            Text(
              'No pudimos cargar los mensajes',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Revisa tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const AppLineIcon(
                  AppIcons.retry,
                  size: AppIconSize.inline,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Reintentar',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
