import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

class ChatConversationPage extends ConsumerStatefulWidget {
  final String threadId;
  final String conversationId;

  const ChatConversationPage({
    super.key,
    required this.threadId,
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
    _messageController.clear();
    final notifier =
        ref.read(chatMessagesProvider(widget.conversationId).notifier);
    final success = await notifier.sendMessage(text);
    if (mounted) setState(() => _isSending = false);

    if (success) {
      // Small post-frame delay to ensure widget is rendered before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      // Refresh thread list to update preview
      ref.invalidate(chatThreadsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.conversationId));
    final conversationsAsync =
        ref.watch(chatConversationsProvider(widget.threadId));
    final threadsAsync = ref.watch(chatThreadsProvider);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: conversationsAsync.when(
          loading: () => const Text('Cargando chat...'),
          error: (_, __) => const Text('Conversación'),
          data: (conversations) {
            final conv = conversations.cast<ChatConversation>().firstWhere(
                  (c) => c.id == widget.conversationId,
                  orElse: () => conversations.first,
                );
            return Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.grey200,
                  radius: 18,
                  child: Icon(Icons.storefront_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.participantName,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        conv.hasQuote
                            ? conv.formattedPrice
                            : 'Cotización pendiente',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: conv.hasQuote
                              ? AppColors.success
                              : AppColors.textSecondary,
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
            // Sticky Quote banner if exists
            conversationsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (conversations) {
                final conv = conversations.cast<ChatConversation>().firstWhere(
                      (c) => c.id == widget.conversationId,
                      orElse: () => conversations.first,
                    );
                if (!conv.hasQuote) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  color: AppColors.successLight.withValues(alpha: 0.8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sell_rounded,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(
                                'Cotización Activa:',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            conv.formattedPrice,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (conv.spareBrand != null &&
                          conv.spareBrand!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.branding_watermark_outlined,
                                size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              'Marca ofrecida: ${conv.spareBrand}',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (conv.sparePhotoUrl != null &&
                          conv.sparePhotoUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              border: Border.all(
                                  color: AppColors.success.withOpacity(0.3)),
                            ),
                            child: Image.network(
                              conv.sparePhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.success, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            // Banner de Imagen del Repuesto de Referencia
            threadsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (threads) {
                final thread = threads.cast<ChatThread>().firstWhere(
                      (t) => t.id == widget.threadId,
                      orElse: () => threads.first,
                    );
                if (thread.fotoUrl == null || thread.fotoUrl!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.8),
                          width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: AppColors.grey50,
                          child: Image.network(
                            thread.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REPUESTO DE REFERENCIA',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              thread.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Messages feed
            Expanded(
              child: messagesAsync.when(
                loading: () => ListView(
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

            // Message compose box
            isLockedForStore
                ? Container(
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
                        borderRadius: BorderRadius.circular(16),
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
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.grey50,
                              borderRadius: BorderRadius.circular(24),
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
                                    horizontal: 18, vertical: 12),
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
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _canSend
                                    ? AppColors.primary
                                    : AppColors.grey300,
                                shape: BoxShape.circle,
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
