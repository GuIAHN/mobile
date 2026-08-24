import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../domain/entities/chat_conversation.dart';
import '../providers/chat_providers.dart';
import '_atoms/status_badge.dart';

/// Vincula un único card a los mensajes de su conversación. El `select` del
/// provider evita que los demás cards se reconstruyan cuando llega un mensaje.
class RealtimeStoreChatCard extends ConsumerWidget {
  const RealtimeStoreChatCard({
    super.key,
    required this.conversation,
    required this.onTap,
    this.consumerPerspective = false,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;
  final bool consumerPerspective;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(
      conversationRealtimeUpdateProvider(
        conversation.realtimeConversationId,
      ),
    );
    final currentUserId = ref.watch(
      currentUserProvider.select((user) => user?.id ?? ''),
    );
    final resolved = applyRealtimeConversationUpdate(
      conversation,
      update,
      currentUserId: currentUserId,
    );

    return StoreChatCard(
      conversation: resolved,
      onTap: onTap,
      consumerPerspective: consumerPerspective,
    );
  }
}

/// Card de bandeja de mensajes — jerarquía limpia tipo inbox.
///
/// Columna derecha: nombre + hora (fila) → preview del mensaje → pie comercial.
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
      case 'CANCELLED':
        return OfferStatus.cancelled;
      case null:
      case 'INQUIRY':
        return OfferStatus.noQuoteYet;
      default:
        return OfferStatus.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final timeStr = Formatters.relativeDate(conv.lastMessageAt);
    final status = _resolveStatus(conv);
    final hasUnread = conv.unreadCount > 0;
    final usesLargeText = MediaQuery.textScalerOf(context).scale(14) > 19;

    final message = conv.lastMessage.trim().isNotEmpty
        ? conv.lastMessage
        : (conv.note?.trim().isNotEmpty == true ? conv.note! : '');

    final semanticLabel = StringBuffer(
      'Chat con ${conv.participantName}, '
      '${(consumerPerspective ? status.consumerLabel : status.label).toLowerCase()}',
    );
    if (conv.hasFormalQuote) {
      semanticLabel.write(', ${conv.formattedTotalCost}');
    }
    if (hasUnread) {
      semanticLabel.write(
          ', ${conv.unreadCount} mensaje${conv.unreadCount > 1 ? 's' : ''} sin leer');
    }
    if (message.isNotEmpty) {
      semanticLabel.write(', último mensaje: $message');
    }

    return Semantics(
      label: semanticLabel.toString(),
      button: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar con badge de no leídos ──────────────────────────
                  if (!usesLargeText) ...[
                    _ClientAvatar(
                      url: conv.participantAvatarUrl,
                      name: conv.participantName,
                      unreadCount: conv.unreadCount,
                      showGenericStore:
                          consumerPerspective && !conv.revealsStoreIdentity,
                    ),
                    const SizedBox(width: 14),
                  ],

                  // ── Columna principal ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre + hora. Con texto grande la fecha baja a una
                        // segunda línea para conservarla completa.
                        if (usesLargeText) ...[
                          Text(
                            conv.participantName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: -0.2,
                              height: 1.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.textMeta,
                            ),
                          ),
                        ] else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  conv.participantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: hasUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    letterSpacing: -0.2,
                                    height: 1.2,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeStr,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: hasUnread
                                      ? AppColors.primary
                                      : AppColors.textMeta,
                                ),
                              ),
                            ],
                          ),
                        if (consumerPerspective &&
                            conv.storeRating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${conv.storeRating!.toStringAsFixed(1)} (${conv.storeReviewCount})',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),

                        // Preview del último mensaje
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (hasUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 7, top: 1),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                key: const Key('chat-card-latest-message'),
                                message.isNotEmpty
                                    ? message
                                    : 'Sin mensajes todavía',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: message.isEmpty
                                    ? GoogleFonts.hankenGrotesk(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                        color: AppColors.textMeta,
                                        fontStyle: FontStyle.italic,
                                      )
                                    : hasUnread
                                        ? GoogleFonts.hankenGrotesk(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            height: 1.4,
                                            color: AppColors.textPrimary,
                                          )
                                        : GoogleFonts.hankenGrotesk(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400,
                                            height: 1.4,
                                            color: AppColors.textSecondary,
                                          ),
                              ),
                            ),
                          ],
                        ),

                        // Pie comercial: estado izquierda + precio naranja derecha
                        if (status != OfferStatus.noQuoteYet ||
                            conv.hasFormalQuote) ...[
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            key: const Key('chat-card-commercial-summary'),
                            builder: (context, constraints) {
                              final statusWidget =
                                  status != OfferStatus.noQuoteYet
                                      ? IntrinsicWidth(
                                          child: StatusBadge(
                                            key: const Key(
                                              'chat-card-status-badge',
                                            ),
                                            status: status,
                                            labelOverride: consumerPerspective
                                                ? status.consumerLabel
                                                : null,
                                          ),
                                        )
                                      : null;
                              final priceWidget = conv.hasFormalQuote
                                  ? Text(
                                      key: const Key('chat-card-price'),
                                      conv.formattedTotalCost,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                        color: AppColors.primary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    )
                                  : null;
                              return Wrap(
                                spacing: 4,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (statusWidget != null) statusWidget,
                                  if (priceWidget != null) priceWidget,
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Componentes internos ─────────────────────────────────────────────────────

class _ClientAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final int unreadCount;
  final bool showGenericStore;

  const _ClientAvatar({
    required this.url,
    required this.name,
    required this.unreadCount,
    required this.showGenericStore,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
    const size = 52.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: Semantics(
              image: true,
              label: showGenericStore
                  ? 'Perfil genérico de la tienda'
                  : 'Foto de perfil de $name',
              child: Container(
                key: showGenericStore
                    ? const Key('generic-store-avatar')
                    : const Key('participant-avatar'),
                width: size,
                height: size,
                color: AppColors.grey100,
                child: !showGenericStore && url != null && url!.isNotEmpty
                    ? Image.network(
                        url!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialFallback(initial),
                      )
                    : showGenericStore
                        ? const Center(
                            child: AppLineIcon(
                              AppIcons.store,
                              size: AppIconSize.leading,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : _initialFallback(initial),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -3,
              top: -3,
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
