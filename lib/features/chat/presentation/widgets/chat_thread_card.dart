import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../../core/domain/enums/service_type.dart';

class ChatThreadCard extends StatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;
  final bool showClientName;

  const ChatThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
    this.showClientName = false,
  });

  @override
  State<ChatThreadCard> createState() => _ChatThreadCardState();
}

class _ChatThreadCardState extends State<ChatThreadCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final timeStr = DateFormat('h:mm a').format(thread.lastActivityAt);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Square folder visual or reference image preview
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          thread.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.folder_open_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 14),
 
              // Right: Content info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Title, Unread Dot & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (thread.unreadCount > 0) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              timeStr,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 10.5,
                                color: AppColors.textDisabled,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
 
                    // Row 2: Category / Request Type & State Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            thread.requestType.label.toUpperCase(),
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (widget.showClientName) ...[
                          const SizedBox(width: 8),
                          _buildStoreRequestBadge(thread),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
 
                    // Row 3: Prominent offer count or client name / offer price
                    if (!widget.showClientName && thread.conversationCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              '${thread.conversationCount} ofertas recibidas',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.showClientName)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            thread.clientName != null
                                ? 'Cliente: ${thread.clientName}'
                                : 'Cliente Anónimo',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (thread.hasOffer && thread.offerPrice != null)
                            Text(
                              'Cotizado: ${Formatters.currency(thread.offerPrice!)}',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      )
                    else
                      Text(
                        thread.conversationCount > 0 ? '${thread.conversationCount} respuestas recibidas' : 'Buscando ofertas...',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                    // Row 4: Last Message Bubble
                    if (thread.lastMessage != null && thread.lastMessage!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: thread.unreadCount > 0
                              ? AppColors.primaryLight.withValues(alpha: 0.2)
                              : AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: thread.unreadCount > 0
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (thread.unreadCount > 0) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ] else ...[
                              const Icon(Icons.done_all_rounded,
                                  size: 14, color: AppColors.textDisabled),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                thread.lastMessage!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12.5,
                                  fontWeight: thread.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: thread.unreadCount > 0
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (thread.unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${thread.unreadCount}',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  Widget _buildStoreRequestBadge(ChatThread thread) {
    Color bg;
    Color fg;
    String text;

    if (thread.hasOffer) {
      switch (thread.offerStatus) {
        case 'BOUGHT':
          bg = AppColors.successLight;
          fg = AppColors.success;
          text = '¡VENDIDA!';
          break;
        case 'DELIVERED':
          bg = AppColors.grey100;
          fg = AppColors.textSecondary;
          text = 'ENTREGADA';
          break;
        default:
          bg = AppColors.primaryMuted;
          fg = AppColors.primary;
          text = 'COTIZADA';
      }
    } else {
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange[800]!;
      text = 'NUEVA SOLICITUD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: fg.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
