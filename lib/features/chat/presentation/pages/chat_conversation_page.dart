import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/extensions.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_message_composer.dart';
import '../widgets/active_offer_header_card.dart';
import '../widgets/confirm_purchase_dialog.dart';
import '../widgets/cancel_purchase_dialog.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../widgets/moderation_blocked_dialog.dart';
import '../widgets/store_contact_sheet.dart';
import '../widgets/quote_input_dialog.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../reviews/presentation/widgets/write_review_bottom_sheet.dart';

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
  bool _isCancelling = false;

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
        },
      );
    } finally {
      if (mounted) setState(() => _isQuoting = false);
    }
  }

  Future<void> _cancelPurchase(ChatConversation details) async {
    if (_isCancelling || details.offerId == null) return;

    final confirmation = await CancelPurchaseDialog.show(context);
    if (confirmation == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      final result = await ref.read(cancelOfferUseCaseProvider)(
        details.offerId!,
        reason: confirmation.reason,
      );

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

      // También se refresca ante 409: el servidor es la fuente de verdad.
      ref.invalidate(
        chatConversationDetailsProvider(widget.conversationId),
      );
      ref.invalidate(myConversationsProvider);
      ref.invalidate(consumerRequestsProvider);
      ref.invalidate(storeSalesRequestsProvider);
      ref.invalidate(storeDashboardProvider);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
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
    final reviewHandledLocally =
        ref.watch(handledStoreReviewProvider(widget.conversationId));
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
          data: (details) => Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  shape: BoxShape.circle,
                  image: details.participantAvatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(details.participantAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: details.participantAvatarUrl == null
                    ? const Icon(Icons.person_rounded,
                        color: AppColors.textSecondary, size: 18)
                    : null,
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
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Cotizar ahora (tienda, oferta en INQUIRY) ────────────────────
            // Arriba y separado del compositor para evitar toques accidentales
            // cerca del botón de enviar mensaje.
            if (isStore &&
                detailsAsync.valueOrNull?.isInquiry == true &&
                detailsAsync.valueOrNull?.offerId != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isQuoting
                        ? null
                        : () => _quoteFromChat(
                              detailsAsync.valueOrNull!.offerId!,
                              detailsAsync.valueOrNull!.subcategoryName ??
                                  'la solicitud',
                            ),
                    icon: _isQuoting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.local_offer_rounded, size: 18),
                    label: Text(
                      'Cotizar ahora',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Active Offer Header ─────────────────────────────────────────
            if (detailsAsync.valueOrNull != null &&
                detailsAsync.valueOrNull!.hasQuote)
              ActiveOfferHeaderCard(
                details: detailsAsync.valueOrNull!,
                reviewHandledLocally: reviewHandledLocally.valueOrNull ?? false,
                reviewHandlingStatusLoading: reviewHandledLocally.isLoading,
                isStore: isStore,
                isCancelling: _isCancelling,
                onCancelPressed: () => _cancelPurchase(
                  detailsAsync.valueOrNull!,
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
                onDeliverPressed: () async {
                  final details = detailsAsync.valueOrNull!;
                  final usecase = ref.read(deliverOfferUseCaseProvider);
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
                    (_) {
                      ref.invalidate(chatConversationDetailsProvider(
                          widget.conversationId));
                      ref.invalidate(myConversationsProvider);
                      ref.invalidate(storeSalesRequestsProvider);
                      ref.invalidate(storeDashboardProvider);
                    },
                  );
                },
                onReviewPressed: () async {
                  final details = detailsAsync.valueOrNull!;
                  final res = await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => WriteReviewBottomSheet(
                      targetId: details.storeUserId ?? '',
                      conversationId: widget.conversationId,
                      providerName: details.participantName,
                    ),
                  );
                  if (res == true && mounted) {
                    await markStoreReviewHandled(ref, widget.conversationId);
                    ref.invalidate(
                        chatConversationDetailsProvider(widget.conversationId));
                  }
                },
                onViewStoreReviewsPressed: () {
                  final details = detailsAsync.valueOrNull!;
                  if (details.storeUserId != null) {
                    context.pushNamed(
                      'providerReviews',
                      pathParameters: {'targetId': details.storeUserId!},
                    );
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
