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

  String _getStoreSubtext(String name) {
    if (name.contains('El Amigo')) {
      return '⭐ 4.9 (124 valoraciones) · Tegucigalpa';
    } else if (name.contains('Automotriz H')) {
      return '⭐ 4.7 (89 valoraciones) · San Pedro Sula';
    } else if (name.contains('Japan Parts')) {
      return '⭐ 4.8 (64 valoraciones) · Choluteca';
    }
    return '⭐ 4.8 (95 valoraciones) · Honduras';
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final timeStr = DateFormat('h:mm a').format(conv.lastMessageAt);
    final subtext = _getStoreSubtext(conv.participantName);

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
              // Left: Square store visual (eBay product-style container)
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
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
                    // Row 1: Name, Unread Dot & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            conv.participantName,
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
                            if (conv.unreadCount > 0) ...[
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
                    const SizedBox(height: 2),

                    // Row 2: Ratings / Location
                    Text(
                      subtext,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Row 3: Prominent Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          conv.formattedPrice,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (conv.hasQuote) ...[
                          const SizedBox(width: 6),
                          Text(
                            conv.isFixedPrice ? 'Precio fijo' : 'Estimado',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: conv.isFixedPrice 
                                  ? AppColors.success 
                                  : AppColors.tertiary,
                            ),
                          ),
                        ],
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
