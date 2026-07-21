import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_conversation.dart';

/// Tarjeta de oferta que recibe el usuario regular, con estética de producto
/// tipo marketplace (eBay / MercadoLibre): foto grande a la izquierda, precio
/// prominente, tienda con logo + badge de confianza y chips de señales reales
/// (distancia, envío). Sin ratings inventados.
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
    final distance = conv.formattedDistance;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar, Store Name, and Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _StoreAvatar(
                            logoUrl: conv.storeLogoUrl,
                            name: conv.participantName,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
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
                                    if (conv.verified) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 16,
                                        color: AppColors.tertiary,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        conv.formattedPrice,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Middle Row: Product Image + Last Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProductImage(
                      photoUrl: conv.sparePhotoUrl,
                      brand: conv.spareBrand,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (conv.lastMessage.trim().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: conv.unreadCount > 0
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.grey50,
                                borderRadius: BorderRadius.circular(12),
                                border: conv.unreadCount > 0
                                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                                    : Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                              ),
                              child: Row(
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 13,
                                        fontWeight: conv.unreadCount > 0
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: conv.unreadCount > 0
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (conv.note != null && conv.note!.trim().isNotEmpty) ...[
                            Text(
                              conv.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                
                // Bottom Row: Chips & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (distance != null)
                          _InfoChip(
                            icon: Icons.near_me_outlined,
                            label: distance,
                            color: AppColors.textSecondary,
                            background: AppColors.grey50,
                            border: true,
                          ),
                        if (conv.hasDelivery)
                          _InfoChip(
                            icon: Icons.local_shipping_rounded,
                            label: 'Envío',
                            color: AppColors.success,
                            background: AppColors.success.withValues(alpha: 0.08),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver oferta',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Imagen del repuesto ofertado (o fallback branded). Incluye un tag de marca
/// superpuesto en la esquina, al estilo de las miniaturas de producto.
class _ProductImage extends StatelessWidget {
  final String? photoUrl;
  final String? brand;

  const _ProductImage({required this.photoUrl, required this.brand});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
              color: AppColors.primaryMuted,
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                    )
                  : const _ImageFallback(),
            ),
          ),
          if (brand != null && brand!.trim().isNotEmpty)
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.settings_suggest_outlined,
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
}

/// Avatar pequeño de la tienda: logo real o inicial como fallback.
class _StoreAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;

  const _StoreAvatar({required this.logoUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl != null && logoUrl!.isNotEmpty
          ? Image.network(
              logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialFallback(initial),
            )
          : _initialFallback(initial),
    );
  }

  Widget _initialFallback(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Chip compacto de señal (distancia, envío, etc.).
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final bool border;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: AppColors.border, width: 0.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
