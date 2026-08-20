import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/active_offer_header_card.dart';
import '../widgets/confirm_purchase_dialog.dart';
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
  final _scrollController = ScrollController();
  bool _canSend = false;
  bool _isSending = false;
  bool _isQuoting = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);
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

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
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
        // violation) instead of the generic SnackBar used for transient
        // errors (disconnects, not-a-participant, etc.).
        if (e is RealtimeRequestException && e.code == 'CONTENT_REJECTED') {
          ModerationBlockedDialog.show(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _quoteFromChat(String offerId, String requestTitle) async {
    final result = await QuoteInputDialog.show(context, requestTitle);
    if (result == null || !mounted) return;

    setState(() => _isQuoting = true);
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final useCase = ref.read(quoteOfferUseCaseProvider);
      final res = await useCase(
        offerId: offerId,
        price: result['price'] as double,
        brand: result['brand'] as String?,
        photoPath: result['photoPath'] as String?,
      );
      res.fold(
        (failure) {
          scaffold.showSnackBar(
            SnackBar(
              content: Text('Error al cotizar: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        (_) {
          scaffold.showSnackBar(const SnackBar(
            content: Text('¡Cotización enviada con éxito!'),
            backgroundColor: AppColors.success,
          ));
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
        backgroundColor: Colors.white,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En línea',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
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
                  height: 44,
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
                        borderRadius: BorderRadius.circular(10),
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
                onBuyPressed: () async {
                  final details = detailsAsync.valueOrNull!;
                  final confirmed = await ConfirmPurchaseDialog.show(
                    context,
                    details: details,
                  );
                  if (confirmed != true) return;

                  if (!context.mounted) return;
                  final scaffold = ScaffoldMessenger.of(context);
                  final usecase = ref.read(buyOfferUseCaseProvider);
                  final result = await usecase(details.offerId!);

                  result.fold(
                    (f) => scaffold.showSnackBar(
                        SnackBar(content: Text('Error: ${f.message}'))),
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
                  final scaffold = ScaffoldMessenger.of(context);
                  final usecase = ref.read(deliverOfferUseCaseProvider);
                  final result = await usecase(details.offerId!);
                  result.fold(
                    (f) => scaffold.showSnackBar(
                        SnackBar(content: Text('Error: ${f.message}'))),
                    (_) {
                      scaffold.showSnackBar(const SnackBar(
                          content: Text('¡Oferta marcada como entregada!')));
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  children: const [
                    MessageBubbleSkeleton(),
                    MessageBubbleSkeleton(alignRight: true),
                    MessageBubbleSkeleton(),
                  ],
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error al cargar mensajes: $err',
                    style: GoogleFonts.hankenGrotesk(color: AppColors.error),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Escribe un mensaje para iniciar la conversación.',
                        style: GoogleFonts.hankenGrotesk(
                            color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
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

            // ── Compose box ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              hintText: 'Escribe un mensaje...',
                              hintStyle: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                color: AppColors.textDisabled,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Send Button
                      Semantics(
                        button: true,
                        label: 'Enviar mensaje',
                        child: GestureDetector(
                          onTap:
                              (_canSend && !_isSending) ? _sendMessage : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _canSend
                                  ? AppColors.primary
                                  : AppColors.grey300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: _canSend
                                        ? Colors.white
                                        : AppColors.textDisabled,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
