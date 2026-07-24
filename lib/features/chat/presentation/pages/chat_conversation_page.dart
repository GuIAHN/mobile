import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/active_offer_header_card.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChange);
    // Mark as read in the background
    Future.microtask(() async {
      await ref.read(markAsReadUseCaseProvider).call(widget.conversationId);
      if (mounted) {
        ref.invalidate(chatThreadsProvider);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final currentRole = ref.watch(currentRoleProvider);
    final isStore = currentRole == UserRole.store;

    final isLockedForStore = isStore &&
        messagesAsync.hasValue &&
        !(messagesAsync.value ?? []).any((m) => !m.isFromMe);

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
            // ── Active Offer Header ─────────────────────────────────────────
            detailsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (details) {
                if (!details.hasQuote) return const SizedBox.shrink();
                return ActiveOfferHeaderCard(
                  details: details,
                  isStore: isStore,
                  onBuyPressed: () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    final usecase = ref.read(buyOfferUseCaseProvider);
                    final result = await usecase(details.offerId!);
                    result.fold(
                      (f) => scaffold.showSnackBar(
                          SnackBar(content: Text('Error: ${f.message}'))),
                      (_) {
                        scaffold.showSnackBar(
                            const SnackBar(content: Text('¡Compra exitosa!')));
                        ref.invalidate(chatConversationDetailsProvider(
                            widget.conversationId));
                        ref.invalidate(myConversationsProvider);
                      },
                    );
                  },
                  onDeliverPressed: () async {
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
                      },
                    );
                  },
                  onReviewPressed: () async {
                    final res = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => WriteReviewBottomSheet(
                        targetId: details.storeUserId ?? '',
                        conversationId: widget.conversationId,
                      ),
                    );
                    if (res == true && mounted) {
                      ref.invalidate(chatConversationDetailsProvider(
                          widget.conversationId));
                    }
                  },
                  onViewStoreReviewsPressed: () {
                    if (details.storeUserId != null) {
                      context.pushNamed(
                        'providerReviews',
                        pathParameters: {'targetId': details.storeUserId!},
                      );
                    }
                  },
                );
              },
            ),

            // ── Messages feed ─────────────────────────────────────────────
            Expanded(
              child: messagesAsync.when(
                loading: () => ListView(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  children: const [
                    MessageBubbleSkeleton(),
                    MessageBubbleSkeleton(alignRight: true),
                    MessageBubbleSkeleton(),
                  ],
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error al cargar mensajes: $err',
                    style:
                        GoogleFonts.hankenGrotesk(color: AppColors.error),
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
            if (isLockedForStore)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.8)),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El chat se activará cuando el cliente responda a tu cotización.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
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
                        onTap: (_canSend && !_isSending)
                            ? _sendMessage
                            : null,
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
              ),
          ],
        ),
      ),
    );
  }
}
