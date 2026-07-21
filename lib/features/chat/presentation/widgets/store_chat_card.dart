import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_conversation.dart';

class StoreChatCard extends StatefulWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const StoreChatCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  State<StoreChatCard> createState() => _StoreChatCardState();
}

class _StoreChatCardState extends State<StoreChatCard> {
  bool _isPressed = false;

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;
    final timeStr = _relativeTime(conv.lastMessageAt);

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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: conv.offerStatus == 'BOUGHT'
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.border,
              width: conv.offerStatus == 'BOUGHT' ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: conv.offerStatus == 'BOUGHT'
                    ? AppColors.success.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Avatar / Photo
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primaryMuted,
                    backgroundImage: conv.participantAvatarUrl != null
                        ? NetworkImage(conv.participantAvatarUrl!)
                        : null,
                    child: conv.participantAvatarUrl == null
                        ? Text(
                            conv.participantName.isNotEmpty
                                ? conv.participantName[0].toUpperCase()
                                : 'C',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  if (conv.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Client Name + Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conv.participantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Row 2: Status Badge + Price
                    Row(
                      children: [
                        _buildStatusBadge(conv.offerStatus),
                        const Spacer(),
                        if (conv.hasQuote)
                          Text(
                            conv.formattedPrice,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),

                    if (conv.spareBrand != null && conv.spareBrand!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Marca: ${conv.spareBrand}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],

                    // Último mensaje (o nota inicial)
                    if (conv.lastMessage.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: conv.unreadCount > 0
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.grey50,
                          borderRadius: BorderRadius.circular(8),
                          border: conv.unreadCount > 0
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                              : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              const SizedBox(width: 8),
                            ] else ...[
                              const Icon(Icons.done_all_rounded,
                                  size: 14, color: AppColors.textDisabled),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                conv.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12.5,
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: conv.unreadCount > 0
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (conv.unreadCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
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
                    ] else if (conv.note != null && conv.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        conv.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: AppColors.textDisabled,
                          fontStyle: FontStyle.italic,
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

  Widget _buildStatusBadge(String? status) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'BOUGHT':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = '¡VENDIDA!';
        icon = Icons.shopping_bag_rounded;
        break;
      case 'DELIVERED':
        bg = AppColors.grey100;
        fg = AppColors.textSecondary;
        label = 'ENTREGADA';
        icon = Icons.check_circle_rounded;
        break;
      case 'DISCARDED':
        bg = AppColors.grey100;
        fg = AppColors.textDisabled;
        label = 'DESCARTADA';
        icon = Icons.cancel_rounded;
        break;
      case 'SENT':
      case 'ACCEPTED':
        bg = AppColors.primaryMuted;
        fg = AppColors.primary;
        label = 'COTIZADA';
        icon = Icons.send_rounded;
        break;
      default:
        bg = AppColors.grey100;
        fg = AppColors.textSecondary;
        label = 'CHAT EN PROGRESO';
        icon = Icons.chat_bubble_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
