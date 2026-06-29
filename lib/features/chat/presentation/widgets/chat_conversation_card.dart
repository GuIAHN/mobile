import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_conversation.dart';

class ChatConversationCard extends StatefulWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ChatConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  State<ChatConversationCard> createState() => _ChatConversationCardState();
}

class _ChatConversationCardState extends State<ChatConversationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final timeStr = DateFormat('h:mm a').format(conv.lastMessageAt);

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Centrado vertical exacto para uniformidad
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conv.participantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Pricing tag cotizada
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: conv.hasQuote 
                                ? AppColors.successLight 
                                : AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sell_rounded,
                                size: 12,
                                color: conv.hasQuote 
                                    ? AppColors.success 
                                    : AppColors.textDisabled,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                conv.formattedPrice,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: conv.hasQuote 
                                      ? AppColors.success 
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (conv.hasQuote && conv.isFixedPrice) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '(Fijo)',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.success,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        
                        if (conv.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${conv.unreadCount}',
                              style: GoogleFonts.hankenGrotesk(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
