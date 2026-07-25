import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_thread.dart';

class ConsumerThreadCard extends StatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const ConsumerThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  State<ConsumerThreadCard> createState() => _ConsumerThreadCardState();
}

class _ConsumerThreadCardState extends State<ConsumerThreadCard> {
  bool _isPressed = false;

  String _formatExpiration() {
    final thread = widget.thread;
    if (thread.isExpired) return 'Expirada';
    if (thread.expiresAt == null) return '';
    final diff = thread.expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expirada';
    if (diff.inHours >= 24) {
      final days = (diff.inHours / 24).floor();
      return 'Expira en ${days}d';
    }
    if (diff.inHours > 0) return 'Expira en ${diff.inHours}h';
    return 'Expira en ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final timeStr = DateFormat('d MMM, h:mm a').format(thread.lastActivityAt);
    final expStr = _formatExpiration();

    final hasOffers = thread.totalOffersCount > 0 || thread.bestOfferPrice != null;
    final isBought = thread.bestOfferStatus == 'BOUGHT' || thread.bestOfferStatus == 'DELIVERED';
    final isClosed = !thread.isOpen || thread.isExpired;

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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBought
                  ? AppColors.success.withValues(alpha: 0.4)
                  : hasOffers
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
              width: isBought || hasOffers ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila 1: Badge de Estado + Timer de Expiración + Fecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(isBought: isBought, isClosed: isClosed, hasOffers: hasOffers),
                    Row(
                      children: [
                        if (!isClosed && expStr.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  expStr,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          timeStr,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fila 2: Foto del repuesto (si existe) + Título del vehículo y Subcategoría
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty) ...[
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.network(
                            thread.fotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.directions_car_rounded,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.title,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (thread.subcategory != null) ...[
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMuted,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      thread.subcategory!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.hankenGrotesk(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (thread.partType != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    thread.partType!.toUpperCase(),
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Nota/Detalle del usuario (si existe)
                if (thread.details != null && thread.details!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 6),
                          child: Icon(Icons.notes_rounded,
                              size: 14, color: AppColors.textSecondary),
                        ),
                        Expanded(
                          child: Text(
                            '"${thread.details}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Fila 3: Información de Mejor Oferta / Ofertas recibidas
                if (thread.bestOfferPrice != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              thread.bestOfferStoreName != null
                                  ? 'Mejor oferta por ${thread.bestOfferStoreName}'
                                  : 'Mejor oferta disponible',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          Formatters.currency(thread.bestOfferPrice!),
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasOffers ? Icons.groups_outlined : Icons.hourglass_empty_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          thread.totalOffersCount > 0
                              ? '${thread.totalOffersCount} cotización${thread.totalOffersCount > 1 ? 'es' : ''} recibida${thread.totalOffersCount > 1 ? 's' : ''}'
                              : 'Esperando respuestas de tiendas cercanas...',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textDisabled, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isBought,
    required bool isClosed,
    required bool hasOffers,
  }) {
    Color bg;
    Color fg;
    String text;

    if (isBought) {
      bg = AppColors.successLight;
      fg = AppColors.success;
      text = 'COMPRADA';
    } else if (isClosed) {
      bg = AppColors.grey100;
      fg = AppColors.textSecondary;
      text = 'CERRADA';
    } else if (hasOffers) {
      bg = AppColors.primaryMuted;
      fg = AppColors.primary;
      text = 'OFERTAS RECIBIDAS';
    } else {
      bg = AppColors.warningLight;
      fg = AppColors.warning;
      text = 'BUSCANDO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: fg,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
