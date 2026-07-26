import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../domain/entities/chat_thread.dart';
import '../providers/chat_providers.dart';
import 'quote_input_dialog.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/status_badge.dart';
import '_atoms/meta_line.dart';
import '_atoms/price_text.dart';
import '_atoms/expiration_label.dart';

/// Card de solicitud de búsqueda — vista tienda.
///
/// Misma estructura de tres zonas que la card del consumidor, pero el footer
/// es una acción (cotizar / marcar entregado) en lugar de un precio, porque
/// aquí la tarea del usuario es **responder**, no comparar.
class ChatThreadCard extends ConsumerStatefulWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const ChatThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
  });

  @override
  ConsumerState<ChatThreadCard> createState() => _ChatThreadCardState();
}

class _ChatThreadCardState extends ConsumerState<ChatThreadCard> {
  bool _isSubmitting = false;

  void _openQuoteDialog() async {
    final thread = widget.thread;
    final result = await QuoteInputDialog.show(context, thread.title);
    if (result == null) return;

    setState(() => _isSubmitting = true);
    try {
      final useCase = ref.read(createQuoteUseCaseProvider);
      final quoteRes = await useCase(
        threadId: thread.id,
        isFixedPrice: result['isFixedPrice'] as bool,
        price: result['price'] as double?,
        minPrice: result['minPrice'] as double?,
        maxPrice: result['maxPrice'] as double?,
        brand: result['brand'] as String?,
        photoPath: result['photoPath'] as String?,
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
        (_) {
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

  String _partTypeLabel(String raw) {
    switch (raw) {
      case 'ORIGINAL':
        return 'Original';
      case 'GENERIC':
        return 'Genérico';
      case 'PERFORMANCE':
        return 'Performance';
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.thread;
    final expStr = expirationLabel(thread.expiresAt, isExpired: thread.isExpired);
    final isUnquoted = !thread.hasOffer;
    final isBought = thread.offerStatus == 'BOUGHT';
    final status = OfferStatusX.fromApi(thread.offerStatus, hasOffer: thread.hasOffer);

    final semanticLabel = StringBuffer(
      'Solicitud de ${thread.clientName ?? "cliente"}, ${thread.title}',
    );
    if (thread.subcategory != null) semanticLabel.write(', ${thread.subcategory}');
    semanticLabel.write(', ${status.label.toLowerCase()}');
    if (thread.distance != null) {
      semanticLabel.write(', a ${thread.distance!.toStringAsFixed(1)} kilómetros');
    }

    return CardShell(
      onTap: widget.onTap,
      semanticLabel: semanticLabel.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zona 1: estado + expiración ──────────────────────────────────
          Row(
            children: [
              Flexible(child: StatusBadge(status: status)),
              const Spacer(),
              if (expStr.isNotEmpty) ...[
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: thread.isExpired ? AppColors.errorInk : AppColors.textMeta,
                ),
                const SizedBox(width: 4),
                Text(
                  expStr,
                  style: CardTokens.meta.copyWith(
                    color: thread.isExpired ? AppColors.errorInk : AppColors.textMeta,
                    fontWeight: thread.isExpired ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: CardTokens.blockGap),

          // ── Zona 2: miniatura + identidad de la solicitud ────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardThumb(url: thread.fotoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CardTokens.title,
                    ),
                    const SizedBox(height: CardTokens.tight),
                    MetaLine(
                      items: [
                        if (thread.subcategory != null) MetaItem(thread.subcategory!),
                        if (thread.partType != null) MetaItem(_partTypeLabel(thread.partType!)),
                      ],
                    ),
                    if (thread.details != null && thread.details!.isNotEmpty) ...[
                      const SizedBox(height: CardTokens.gap),
                      Text(
                        thread.details!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CardTokens.body,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: CardTokens.blockGap),

          // ── Zona 3: contexto del cliente ─────────────────────────────────
          MetaLine(
            items: [
              MetaItem(thread.clientName ?? 'Cliente', icon: Icons.person_outline_rounded),
              if (thread.distance != null)
                MetaItem(
                  '${thread.distance!.toStringAsFixed(1)} km',
                  icon: Icons.near_me_outlined,
                  color: AppColors.celesteInk,
                ),
              if (isUnquoted)
                MetaItem(
                  thread.totalOffersCount > 0
                      ? '${thread.totalOffersCount} cotización${thread.totalOffersCount > 1 ? 'es' : ''}'
                      : 'Sé el primero',
                  icon: Icons.storefront_outlined,
                  color: thread.totalOffersCount > 0 ? null : AppColors.primaryInk,
                ),
            ],
          ),

          // ── Footer: acción ───────────────────────────────────────────────
          const CardDivider(),
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else if (isUnquoted)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openQuoteDialog,
                icon: const Icon(Icons.local_offer_rounded, size: 18),
                label: Text('Cotizar ahora', style: CardTokens.button),
                style: ElevatedButton.styleFrom(
                  // primaryDark: blanco sobre primary da 3.33:1 (falla AA),
                  // sobre primaryDark da 5.1:1.
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else if (isBought)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _markDelivered,
                icon: const Icon(Icons.local_shipping_rounded, size: 18),
                label: Text('Marcar como entregado', style: CardTokens.button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TU COTIZACIÓN', style: CardTokens.overline),
                      const SizedBox(height: 2),
                      PriceText(
                        amount: thread.offerPrice,
                        style: CardTokens.price.copyWith(color: AppColors.primary),
                        fallback: 'Enviada',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: widget.onTap,
                    style: OutlinedButton.styleFrom(
                      // El OutlinedButtonTheme global fuerza ancho infinito.
                      minimumSize: Size.zero,
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Ver chat', style: CardTokens.button),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
