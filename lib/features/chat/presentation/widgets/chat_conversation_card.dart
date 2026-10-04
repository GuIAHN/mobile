import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../domain/entities/chat_conversation.dart';
import '../providers/chat_providers.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/meta_line.dart';
import '_atoms/price_text.dart';

/// Variante reactiva del card de oferta. Sólo observa la conversación que
/// representa, por lo que un mensaje no reconstruye la lista ni el resumen de
/// la solicitud.
class RealtimeChatConversationCard extends ConsumerWidget {
  const RealtimeChatConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final ChatConversation conversation;
  final VoidCallback onTap;

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
    var resolved = applyRealtimeConversationUpdate(
      conversation,
      update,
      currentUserId: currentUserId,
    );
    final conversationId = conversation.conversationId;
    if (conversationId != null &&
        currentUserId.isNotEmpty &&
        resolved.lastMessageIsFromMe == null &&
        resolved.lastMessage.trim().isNotEmpty) {
      final latestMessage = ref
          .watch(
            latestConversationMessageProvider(
              (
                conversationId: conversationId,
                lastMessageAt: resolved.lastMessageAt,
                lastMessage: resolved.lastMessage,
              ),
            ),
          )
          .valueOrNull;
      resolved = applyLatestMessageAuthorship(resolved, latestMessage);
    }

    return ChatConversationCard(
      conversation: resolved,
      onTap: onTap,
    );
  }
}

/// Card de oferta recibida — vista consumidor.
///
/// Es la card donde el usuario **compara**, así que el precio es el elemento
/// dominante (24px w900) y todo lo demás queda subordinado. Las señales de
/// confianza (rating, distancia, envío) se agrupan en una sola línea celeste
/// en vez de tres chips rellenos que competían con el precio.
class ChatConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ChatConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final conv = conversation;
    final distance = conv.formattedDistance;
    final hasUnread = conv.unreadCount > 0;
    final hasFormalQuote = conv.hasFormalQuote;
    final hasLastMessage = conv.lastMessage.trim().isNotEmpty;
    final message = hasLastMessage
        ? conv.lastMessage
        : (conv.note ??
            (hasFormalQuote
                ? 'Nueva cotización recibida'
                : 'La tienda inició una conversación'));

    final semanticLabel = StringBuffer(
      hasFormalQuote
          ? 'Cotización de ${conv.participantName}'
          : 'Conversación con ${conv.participantName}, aún sin cotización',
    );
    if (conv.verified) semanticLabel.write(', tienda verificada');
    if (conv.storeRating != null) {
      semanticLabel
          .write(', calificación ${conv.storeRating!.toStringAsFixed(1)} de 5');
    }
    if (hasFormalQuote) {
      semanticLabel.write(', ${conv.formattedTotalCost}');
    }
    if (distance != null) semanticLabel.write(', a $distance');
    if (hasUnread) semanticLabel.write(', mensajes sin leer');

    return CardShell(
      onTap: onTap,
      semanticLabel: semanticLabel.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cuerpo: producto + tienda + precio ───────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumb(
                photoUrl: conv.sparePhotoUrl,
                brand: conv.spareBrand,
                logoUrl: conv.storeLogoUrl,
                storeName: conv.participantName,
                revealStoreIdentity: conv.revealsStoreIdentity,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tienda + verificación
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            conv.participantName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CardTokens.title,
                          ),
                        ),
                        if (conv.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: AppColors.celeste),
                        ],
                      ],
                    ),
                    const SizedBox(height: CardTokens.tight),

                    // Señales de confianza en una sola línea celeste
                    MetaLine(
                      color: AppColors.celesteInk,
                      items: [
                        if (conv.storeRating != null)
                          MetaItem(
                            '${conv.storeRating!.toStringAsFixed(1)} (${conv.storeReviewCount})',
                            icon: Icons.star_rounded,
                          ),
                        if (distance != null)
                          MetaItem(distance, icon: Icons.near_me_outlined),
                        MetaItem(
                          conv.hasDelivery ? 'Envío' : 'Retiro en tienda',
                          icon: conv.hasDelivery
                              ? Icons.local_shipping_rounded
                              : Icons.storefront_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Precio protagonista
                    if (hasFormalQuote)
                      PriceText(
                        amount: conv.totalCost ?? conv.price,
                        style: CardTokens.priceHero,
                      )
                    else
                      Text(
                        'Aún sin cotización',
                        style: CardTokens.metaStrong.copyWith(
                          color: AppColors.textMeta,
                        ),
                      ),
                    if (hasFormalQuote && conv.deliveryCost != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        conv.deliveryCost == 0
                            ? 'Total · delivery gratis'
                            : 'Total con delivery',
                        style: CardTokens.meta,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // ── Footer: mensaje + acción ─────────────────────────────────────
          const CardDivider(),
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
                child: Text.rich(
                  TextSpan(
                    children: [
                      if (hasLastMessage && conv.lastMessageIsFromMe != null)
                        TextSpan(
                          text: conv.lastMessageIsFromMe!
                              ? 'Tú: '
                              : '${conv.participantName}: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      TextSpan(text: message),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasUnread ? CardTokens.bodyUnread : CardTokens.body,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    // El ElevatedButtonTheme global fuerza ancho infinito.
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    hasFormalQuote ? 'Ver cotización' : 'Ver chat',
                    style: CardTokens.button,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Miniatura del repuesto con el logo de la tienda superpuesto y la marca
/// como etiqueta inferior.
class _ProductThumb extends StatelessWidget {
  final String? photoUrl;
  final String? brand;
  final String? logoUrl;
  final String storeName;
  final bool revealStoreIdentity;

  const _ProductThumb({
    required this.photoUrl,
    required this.brand,
    required this.logoUrl,
    required this.storeName,
    required this.revealStoreIdentity,
  });

  @override
  Widget build(BuildContext context) {
    const size = CardTokens.thumbSizeLarge;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(CardTokens.thumbRadius),
            child: Container(
              width: size,
              height: size,
              color: AppColors.grey100,
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : _fallback(),
                    )
                  : _fallback(),
            ),
          ),

          // Marca del repuesto — etiqueta discreta sobre la imagen
          if (brand != null && brand!.trim().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(CardTokens.thumbRadius),
                    bottomRight: Radius.circular(CardTokens.thumbRadius),
                  ),
                ),
                child: Text(
                  brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

          // Logo de la tienda
          Positioned(
            top: -5,
            left: -5,
            child: _StoreAvatar(
              logoUrl: logoUrl,
              name: storeName,
              size: 30,
              revealIdentity: revealStoreIdentity,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => const Center(
        child:
            Icon(Icons.inventory_2_rounded, color: AppColors.grey400, size: 30),
      );
}

class _StoreAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;
  final bool revealIdentity;

  const _StoreAvatar({
    required this.logoUrl,
    required this.name,
    required this.size,
    required this.revealIdentity,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: revealIdentity
          ? 'Foto de perfil de $name'
          : 'Perfil genérico de la tienda',
      child: Container(
        key: revealIdentity
            ? const Key('revealed-store-avatar')
            : const Key('generic-store-avatar'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: revealIdentity && logoUrl != null && logoUrl!.isNotEmpty
            ? Image.network(
                logoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _genericFallback(),
              )
            : _genericFallback(),
      ),
    );
  }

  Widget _genericFallback() => Container(
        color: AppColors.grey100,
        child: const Center(
          child: AppLineIcon(
            AppIcons.store,
            size: AppIconSize.inline,
            color: AppColors.textSecondary,
          ),
        ),
      );
}
