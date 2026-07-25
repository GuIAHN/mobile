import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../../core/domain/enums/service_type.dart';
import '../providers/chat_providers.dart';
import 'quote_input_dialog.dart';

class ChatThreadCard extends ConsumerStatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;
  final bool showClientName;

  const ChatThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
    this.showClientName = false,
  });

  @override
  ConsumerState<ChatThreadCard> createState() => _ChatThreadCardState();
}

class _ChatThreadCardState extends ConsumerState<ChatThreadCard> {
  bool _isPressed = false;
  bool _isSubmitting = false;

  void _openQuoteDialog() async {
    final thread = widget.thread;
    final result = await QuoteInputDialog.show(context, thread.title);
    if (result == null) return;

    setState(() => _isSubmitting = true);
    try {
      final isFixed = result['isFixedPrice'] as bool;
      final price = result['price'] as double?;
      final minPrice = result['minPrice'] as double?;
      final maxPrice = result['maxPrice'] as double?;
      final brand = result['brand'] as String?;
      final photoPath = result['photoPath'] as String?;

      final useCase = ref.read(createQuoteUseCaseProvider);
      final quoteRes = await useCase(
        threadId: thread.id,
        isFixedPrice: isFixed,
        price: price,
        minPrice: minPrice,
        maxPrice: maxPrice,
        brand: brand,
        photoPath: photoPath,
      );

      quoteRes.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al enviar cotización: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (newConv) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Cotización enviada con éxito!'),
                backgroundColor: AppColors.success,
              ),
            );
            ref.invalidate(chatThreadsProvider);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _markDelivered() async {
    final thread = widget.thread;
    if (thread.offerId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(deliverOfferUseCaseProvider);
      final result = await useCase(thread.offerId!);

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al marcar entrega: ${failure.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Oferta marcada como ENTREGADA!'),
                backgroundColor: AppColors.success,
              ),
            );
            ref.invalidate(chatThreadsProvider);
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatExpiration() {
    final thread = widget.thread;
    if (thread.expiresAt == null) return '';
    if (thread.isExpired) return 'Expirada';

    final diff = thread.expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expirada';

    if (diff.inHours >= 24) {
      final days = (diff.inHours / 24).ceil();
      return 'Expira en ${days}d';
    } else if (diff.inHours >= 1) {
      return 'Expira en ${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return 'Expira en ${diff.inMinutes}m';
    }
    return 'Expira pronto';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showClientName) {
      return _buildStoreCard(context);
    }
    return _buildConsumerCard(context);
  }

  // ── Tarjeta para Tiendas (Store View) ────────────────────────────────────
  Widget _buildStoreCard(BuildContext context) {
    final thread = widget.thread;
    final timeStr = DateFormat('h:mm a').format(thread.lastActivityAt);
    final expStr = _formatExpiration();
    final isUnquoted = !thread.hasOffer;
    final isBought = thread.offerStatus == 'BOUGHT';

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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnquoted
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : isBought
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.border,
              width: isUnquoted || isBought ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isUnquoted
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Badges de Estado + Expiración + Hora
              Row(
                children: [
                  _buildStoreStatusBadge(thread),
                  const Spacer(),
                  if (expStr.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: thread.isExpired
                            ? AppColors.errorLight
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: thread.isExpired
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            expStr,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: thread.isExpired
                                  ? AppColors.error
                                  : AppColors.textSecondary,
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
              const SizedBox(height: 12),

              // Fila 2: Imagen (si existe) + Título del vehículo y Subcategoría
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty) ...[
                    Container(
                      width: 64,
                      height: 64,
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

              // Detalle especificado por el cliente (si existe)
              if (thread.details != null && thread.details!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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

              const SizedBox(height: 10),

              // Fila 3: Información de cliente y cercanía
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        thread.clientName ?? "Cliente",
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (thread.distance != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${thread.distance!.toStringAsFixed(1)} km',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              if (isUnquoted) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      thread.totalOffersCount > 0
                          ? Icons.storefront_outlined
                          : Icons.flash_on_rounded,
                      size: 14,
                      color: thread.totalOffersCount > 0
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        thread.totalOffersCount > 0
                            ? '${thread.totalOffersCount} cotización${thread.totalOffersCount > 1 ? 'es' : ''} enviada${thread.totalOffersCount > 1 ? 's' : ''} por otras tiendas'
                            : 'Sin cotizaciones aún. ¡Sé el primero en ofertar!',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: thread.totalOffersCount > 0
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Fila 4: Botones de Acción Directa (CTA)
              if (_isSubmitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else if (isUnquoted)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openQuoteDialog,
                    icon: const Icon(Icons.local_offer_rounded, size: 18),
                    label: Text(
                      'COTIZAR AHORA',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (isBought)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _markDelivered,
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: Text(
                      'MARCAR COMO ENTREGADO',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else if (thread.hasOffer && thread.offerPrice != null)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Tu cotización: ${Formatters.currency(thread.offerPrice!)}',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary, width: 1.2),
                        ),
                        child: Text(
                          'Ver Chat',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tarjeta para Cliente (Consumer View) ─────────────────────────────────
  Widget _buildConsumerCard(BuildContext context) {
    final thread = widget.thread;
    final timeStr = DateFormat('h:mm a').format(thread.lastActivityAt);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: thread.fotoUrl != null && thread.fotoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          thread.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.textSecondary,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.folder_open_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            thread.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 10.5,
                            color: AppColors.textDisabled,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        thread.requestType.label.toUpperCase(),
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (thread.conversationCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.successLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Text(
                              '${thread.conversationCount} ofertas recibidas',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Buscando ofertas...',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreStatusBadge(ChatThread thread) {
    Color bg;
    Color fg;
    String text;

    if (thread.hasOffer) {
      switch (thread.offerStatus) {
        case 'BOUGHT':
          bg = AppColors.successLight;
          fg = AppColors.success;
          text = '¡VENDIDA!';
          break;
        case 'DELIVERED':
          bg = AppColors.grey200;
          fg = AppColors.textSecondary;
          text = 'ENTREGADA';
          break;
        default:
          bg = AppColors.tertiaryMuted;
          fg = AppColors.tertiary;
          text = 'COTIZADA';
      }
    } else {
      bg = AppColors.primaryMuted;
      fg = AppColors.primary;
      text = 'NUEVA SOLICITUD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: fg.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!thread.hasOffer) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            text,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: fg,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
