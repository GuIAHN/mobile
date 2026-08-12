import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../domain/entities/chat_conversation.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/status_badge.dart';
import '_atoms/price_text.dart';

/// Card de chat/oferta enviada — vista tienda, tab "Mis Chats".
///
/// Fila compacta: es una bandeja de conversaciones, no una lista de
/// comparación, así que no lleva divisor ni footer. Densidad alta pero con
/// jerarquía clara: nombre → estado → mensaje, y el precio alineado a la
/// derecha para que se pueda escanear la columna verticalmente.
class StoreChatCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const StoreChatCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  /// A diferencia de [OfferStatusX.fromApi] (pensado para `ChatThread`, donde
  /// "sin oferta" implica una acción pendiente de cotizar), aquí un
  /// `offerStatus` nulo es una conversación directa sin cotización formal —
  /// un estado neutro. Por eso se resuelve aparte.
  OfferStatus _resolveStatus(ChatConversation conv) {
    switch (conv.offerStatus) {
      case 'SENT':
        return OfferStatus.sent;
      case 'ACCEPTED':
        return OfferStatus.accepted;
      case 'DISCARDED':
        return OfferStatus.discarded;
      case 'BOUGHT':
        return OfferStatus.bought;
      case 'DELIVERED':
        return OfferStatus.delivered;
      default:
        return OfferStatus.noQuoteYet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final timeStr = Formatters.relativeDate(conv.lastMessageAt);
    final status = _resolveStatus(conv);
    final hasUnread = conv.unreadCount > 0;

    final message = conv.lastMessage.trim().isNotEmpty
        ? conv.lastMessage
        : (conv.note?.trim().isNotEmpty == true ? conv.note! : '');

    final semanticLabel = StringBuffer(
      'Chat con ${conv.participantName}, ${status.label.toLowerCase()}',
    );
    if (conv.hasQuote) semanticLabel.write(', ${conv.formattedPrice}');
    if (hasUnread) {
      semanticLabel.write(', ${conv.unreadCount} mensaje${conv.unreadCount > 1 ? 's' : ''} sin leer');
    }

    return CardShell(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      semanticLabel: semanticLabel.toString(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClientAvatar(
            url: conv.participantAvatarUrl,
            name: conv.participantName,
            unreadCount: conv.unreadCount,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre + hora
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conv.participantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CardTokens.title.copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(timeStr, style: CardTokens.meta),
                  ],
                ),
                const SizedBox(height: CardTokens.gap),

                // Estado + precio
                Row(
                  children: [
                    Flexible(child: StatusBadge(status: status)),
                    const Spacer(),
                    if (conv.hasQuote)
                      PriceText(amount: conv.price),
                  ],
                ),

                // Último mensaje
                if (message.isNotEmpty) ...[
                  const SizedBox(height: CardTokens.gap),
                  Row(
                    children: [
                      if (hasUnread) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hasUnread ? CardTokens.bodyUnread : CardTokens.body,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final int unreadCount;

  const _ClientAvatar({
    required this.url,
    required this.name,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';

    return SizedBox(
      width: CardTokens.avatarSize,
      height: CardTokens.avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Container(
              width: CardTokens.avatarSize,
              height: CardTokens.avatarSize,
              color: AppColors.grey100,
              child: url != null && url!.isNotEmpty
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initialFallback(initial),
                    )
                  : _initialFallback(initial),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initialFallback(String initial) => Center(
        child: Text(
          initial,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
