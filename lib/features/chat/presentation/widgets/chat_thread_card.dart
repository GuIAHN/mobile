import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: thread.conversationCount == 0
                                  ? Colors.orange.withValues(alpha: 0.12)
                                  : AppColors.successLight.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: thread.conversationCount == 0
                                    ? Colors.orange.withValues(alpha: 0.4)
                                    : AppColors.success.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              thread.conversationCount == 0 ? 'NUEVA SOLICITUD' : 'COTIZADA',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: thread.conversationCount == 0 ? Colors.orange[800] : AppColors.success,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
 
                    // Row 3: Prominent offer count or client name
                    Text(
                      widget.showClientName && thread.clientName != null
                          ? 'Cliente: ${thread.clientName}'
                          : '${thread.conversationCount} respuestas recibidas',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: thread.conversationCount > 0 
                            ? AppColors.success 
                            : AppColors.textSecondary,
                      ),
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
