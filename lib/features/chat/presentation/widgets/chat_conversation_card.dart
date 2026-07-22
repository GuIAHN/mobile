import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_conversation.dart';

/// Tarjeta de oferta que recibe el usuario regular, rediseñada con el layout
/// premium de marketplace: imagen cuadrada grande a la izquierda, detalles a la
/// derecha con precio vibrante y chips, y el mensaje en la parte inferior.
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
    final distance = conv.formattedDistance;
    final timeStr = _relativeTime(conv.lastMessageAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          highlightColor: AppColors.grey100,
          splashColor: AppColors.grey200,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Section: Product Image & Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image (Square)
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _ProductImage(
                            photoUrl: conv.sparePhotoUrl,
                            brand: conv.spareBrand,
                            size: 90,
                          ),
                          // Store Avatar overlapping the top-left corner
                          Positioned(
                            top: -6,
                            left: -6,
                            child: _StoreAvatar(
                              logoUrl: conv.storeLogoUrl,
                              name: conv.participantName,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Details Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Store Name & Verification
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
                          
                          // Rating & Time
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '4.8 (124)', // Placeholder rating based on the prompt
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• $timeStr',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Price
                          Text(
                            conv.formattedPrice,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.1,
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Distance and Delivery Chips
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
                                  background: AppColors.success.withValues(alpha: 0.1),
                                  border: true,
                                  borderColor: AppColors.success.withValues(alpha: 0.2),
                                )
                              else
                                _InfoChip(
                                  icon: Icons.storefront_rounded,
                                  label: 'Retiro en tienda',
                                  color: AppColors.textSecondary,
                                  background: AppColors.grey50,
                                  border: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                
                // 2. Bottom Section: Last Message & Action Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Last Message Bubble
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: conv.unreadCount > 0
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border: conv.unreadCount > 0
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.2))
                              : Border.all(color: Colors.transparent),
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
                                  size: 16, color: AppColors.textDisabled),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                conv.lastMessage.trim().isNotEmpty
                                    ? conv.lastMessage
                                    : (conv.note ?? 'Nueva oferta recibida'),
                                maxLines: 1,
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
                    ),
                    const SizedBox(width: 12),
                    
                    // Call to Action
                    ElevatedButton(
                      onPressed: widget.onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero, // Fix: Override global full-width button theme
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Ver Oferta',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
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

class _ProductImage extends StatelessWidget {
  final String? photoUrl;
  final String? brand;
  final double size;

  const _ProductImage({
    required this.photoUrl,
    required this.brand,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: size,
              height: size,
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  brand!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
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
        Icons.inventory_2_rounded,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final double size;

  const _StoreAvatar({
    required this.logoUrl,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
          fontSize: size * 0.45,
          fontWeight: FontWeight.w900,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final bool border;
  final Color? borderColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.border = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: border ? Border.all(color: borderColor ?? AppColors.border, width: 0.5) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
