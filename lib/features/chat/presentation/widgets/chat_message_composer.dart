import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';

/// Compositor del chat: una cápsula de escritura y una acción circular
/// independiente, siguiendo el patrón visual de mensajería móvil.
class ChatMessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  const ChatMessageComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final enabled = canSend && !isSending;

    return Padding(
      key: const ValueKey('chat-composer-shell'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: AnimatedContainer(
              key: const ValueKey('chat-composer-input'),
              duration: duration,
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: focusNode.hasFocus
                      ? AppColors.primary.withValues(alpha: 0.42)
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.055),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  if (focusNode.hasFocus)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                keyboardAppearance: Brightness.light,
                onTapOutside: (_) => focusNode.unfocus(),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  hintText: 'Escribe un mensaje…',
                  hintStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            key: const ValueKey('chat-composer-send'),
            duration: duration,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primary : AppColors.primaryMuted,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : const [],
            ),
            child: IconButton(
              tooltip: 'Enviar mensaje',
              onPressed: enabled ? onSend : null,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textOnPrimary,
                disabledForegroundColor:
                    AppColors.primary.withValues(alpha: 0.42),
                padding: EdgeInsets.zero,
              ),
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : const AppLineIcon(
                      AppIcons.send,
                      size: AppIconSize.leading,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
