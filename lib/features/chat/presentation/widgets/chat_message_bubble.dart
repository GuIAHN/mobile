import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../shared/widgets/image_viewer_dialog.dart';
import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message.isFromMe;
    final time = DateFormat('h:mm a').format(message.createdAt);

    if (message.type == MessageType.system) {
      return _SystemMessage(message: message, time: time);
    }

    final maxWidth = MediaQuery.sizeOf(context).width >= 600
        ? 480.0
        : MediaQuery.sizeOf(context).width * 0.78;
    final sender = isMe ? 'Tú' : message.senderName;
    final isImage = message.type == MessageType.image;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: isImage
            ? '$sender envió una imagen a las $time. Toca para ampliarla.'
            : '$sender: ${message.content}. $time',
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: DecoratedBox(
                  key: Key(
                    isMe
                        ? 'outgoing-message-bubble'
                        : 'incoming-message-bubble',
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isMe ? 22 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 22),
                    ),
                    border: Border.all(
                      color: isMe ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.035),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isImage
                      ? _MessageImage(
                          imageUrl: message.content,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(21),
                            topRight: const Radius.circular(21),
                            bottomLeft: Radius.circular(isMe ? 21 : 5),
                            bottomRight: Radius.circular(isMe ? 5 : 21),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            message.content,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15.5,
                              fontWeight:
                                  isMe ? FontWeight.w600 : FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.42,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  time,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMeta,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final ChatMessage message;
  final String time;

  const _SystemMessage({required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    final normalized = message.content.toLowerCase();
    final isCancellation = normalized.contains('cancel') ||
        normalized.contains('anulad') ||
        normalized.contains('anuló');
    final isPurchase = !isCancellation &&
        (normalized.contains('compra') || normalized.contains('comprado'));
    final foreground = isCancellation
        ? AppColors.errorInk
        : isPurchase
            ? AppColors.successInk
            : AppColors.textSecondary;
    final background = isCancellation
        ? AppColors.errorLight
        : isPurchase
            ? AppColors.successLight
            : AppColors.grey100;
    final border = isCancellation
        ? AppColors.error.withValues(alpha: 0.3)
        : isPurchase
            ? AppColors.success.withValues(alpha: 0.28)
            : AppColors.border;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: 'Actualización: ${message.content}. $time',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 24),
        child: DecoratedBox(
          key: Key(
            isCancellation
                ? 'cancelled-system-message'
                : isPurchase
                    ? 'success-system-message'
                    : 'neutral-system-message',
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                AppLineIcon(
                  isCancellation
                      ? AppIcons.cancellation
                      : isPurchase
                          ? AppIcons.success
                          : AppIcons.info,
                  size: AppIconSize.inline,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: message.content),
                        const WidgetSpan(child: SizedBox(width: 8)),
                        TextSpan(
                          text: time,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageImage extends StatelessWidget {
  final String imageUrl;
  final BorderRadius borderRadius;

  const _MessageImage({
    required this.imageUrl,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = resolveMediaUrl(imageUrl) ?? imageUrl;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: AppColors.grey100,
        child: InkWell(
          onTap: () => ImageViewerDialog.show(
            context,
            resolvedImageUrl,
            title: 'Imagen del chat',
          ),
          child: SizedBox(
            width: 240,
            height: 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  resolvedImageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                  errorBuilder: (_, __, ___) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No se pudo cargar la imagen',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.hankenGrotesk(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  right: 12,
                  bottom: 12,
                  child: _ExpandImageBadge(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandImageBadge extends StatelessWidget {
  const _ExpandImageBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: AppLineIcon(
          AppIcons.externalLink,
          size: AppIconSize.inline,
          color: Colors.white,
        ),
      ),
    );
  }
}
