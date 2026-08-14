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

/// Card compacta de conversación para la bandeja de Chats.
///
/// La jerarquía replica una bandeja de mensajería: identidad y hora, último
/// mensaje y, como cierre, un único resumen comercial que agrupa estado y
/// precio. Ningún dato comercial compite con el nombre o queda flotando en
/// otro extremo de la card.
class StoreChatCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;
  final bool consumerPerspective;

  const StoreChatCard({
    super.key,
    required this.conversation,
    required this.onTap,
    this.consumerPerspective = false,
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
      'Chat con ${conv.participantName}, '
      '${(consumerPerspective ? status.consumerLabel : status.label).toLowerCase()}',
    );
    if (conv.hasQuote) semanticLabel.write(', ${conv.formattedPrice}');
    if (hasUnread) {
      semanticLabel.write(
          ', ${conv.unreadCount} mensaje${conv.unreadCount > 1 ? 's' : ''} sin leer');
    }
    if (message.isNotEmpty) {
      semanticLabel.write(', último mensaje: $message');
    }

    return CardShell(
      onTap: onTap,
      padding: const EdgeInsets.all(CardTokens.pad),
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
                _ConversationHeader(
                  participantName: conv.participantName,
                  timeLabel: timeStr,
                ),
                const SizedBox(height: CardTokens.tight),

                // El mensaje es el segundo nivel de lectura, inmediatamente
                // después de la identidad como en una bandeja convencional.
                Text(
                  message.isNotEmpty ? message : 'Sin mensajes todavía',
                  key: const Key('chat-card-latest-message'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: message.isEmpty
                      ? CardTokens.meta
                      : hasUnread
                          ? CardTokens.bodyUnread
                          : CardTokens.body,
                ),

                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                ),
                const SizedBox(height: 10),

                // Estado y precio constituyen una sola unidad transaccional.
                _CommercialSummary(
                  status: status,
                  labelOverride:
                      consumerPerspective ? status.consumerLabel : null,
                  hasQuote: conv.hasQuote,
                  price: conv.price,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  final String participantName;
  final String timeLabel;

  const _ConversationHeader({
    required this.participantName,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name = Text(
      participantName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CardTokens.title.copyWith(fontSize: 16),
    );
    final time = Text(
      timeLabel,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CardTokens.meta,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final shouldStack = constraints.maxWidth < 200 || scaledBody > 19;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name,
              const SizedBox(height: 2),
              time,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: name),
            const SizedBox(width: 8),
            Flexible(child: time),
          ],
        );
      },
    );
  }
}

class _CommercialSummary extends StatelessWidget {
  final OfferStatus status;
  final String? labelOverride;
  final bool hasQuote;
  final double? price;

  const _CommercialSummary({
    required this.status,
    required this.labelOverride,
    required this.hasQuote,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final statusBadge = StatusBadge(
      key: const Key('chat-card-status-badge'),
      status: status,
      labelOverride: labelOverride,
    );
    final priceBlock = _OfferPrice(price: price);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final shouldStack = constraints.maxWidth < 230 || scaledBody > 19;

        return Semantics(
          container: true,
          child: Container(
            key: const Key('chat-card-commercial-summary'),
            child: shouldStack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      statusBadge,
                      if (hasQuote) ...[
                        const SizedBox(height: CardTokens.gap),
                        priceBlock,
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(child: statusBadge),
                      if (hasQuote) ...[
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        const SizedBox(width: 12),
                        priceBlock,
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _OfferPrice extends StatelessWidget {
  final double? price;

  const _OfferPrice({required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('chat-card-price'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('OFERTA', style: CardTokens.overline),
        const SizedBox(height: 2),
        PriceText(amount: price),
      ],
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
