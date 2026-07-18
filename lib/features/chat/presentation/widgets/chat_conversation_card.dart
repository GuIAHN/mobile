import 'dart:ui' show FontFeature;
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
  bool _isPressed = false;

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    // Formato numérico (sin nombres de mes) para no depender de locale.
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(
                  photoUrl: conv.sparePhotoUrl,
                  brand: conv.spareBrand,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _OfferInfo(
                    conv: conv,
                    timeStr: _relativeTime(conv.lastMessageAt),
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

/// Imagen del repuesto ofertado (o fallback branded). Incluye un tag de marca
/// superpuesto en la esquina, al estilo de las miniaturas de producto.
class _ProductImage extends StatelessWidget {
  final String? photoUrl;
  final String? brand;

  const _ProductImage({required this.photoUrl, required this.brand});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 92,
              height: 92,
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text(
                  brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9.5,
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
        size: 30,
      ),
    );
  }
}

/// Columna derecha: precio, tienda + verificado, y chips de confianza.
class _OfferInfo extends StatelessWidget {
  final ChatConversation conv;
  final String timeStr;

  const _OfferInfo({required this.conv, required this.timeStr});

  @override
  Widget build(BuildContext context) {
    final distance = conv.formattedDistance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Precio prominente + tiempo
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                conv.formattedPrice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.05,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Fila de tienda: logo + nombre + verificado
        Row(
          children: [
            _StoreAvatar(
                logoUrl: conv.storeLogoUrl, name: conv.participantName),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                conv.participantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (conv.verified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                size: 15,
                color: AppColors.tertiary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Chips de señales reales
        Wrap(
          spacing: 6,
          runSpacing: 6,
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
            if (conv.hasConversation)
              _InfoChip(
                icon: Icons.forum_rounded,
                label: 'Chat activo',
                color: AppColors.tertiary,
                background: AppColors.tertiary.withValues(alpha: 0.08),
              ),
          ],
        ),

        // Nota de la tienda (si la envió)
        if (conv.note != null && conv.note!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            conv.note!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Afordancia de acción
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Ver oferta',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
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
