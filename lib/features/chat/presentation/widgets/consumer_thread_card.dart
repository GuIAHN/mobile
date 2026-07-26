import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../domain/entities/chat_thread.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/status_badge.dart';
import '_atoms/meta_line.dart';
import '_atoms/price_text.dart';
import '_atoms/expiration_label.dart';

/// Card de solicitud de búsqueda — vista consumidor.
///
/// Estructura en tres zonas separadas por espacio en blanco:
///   1. Header  — estado (único relleno) + expiración
///   2. Cuerpo  — miniatura + título + categoría + nota
///   3. Footer  — mejor oferta recibida, con el precio como ancla
class ConsumerThreadCard extends StatelessWidget {
  final ChatThread thread;
  final VoidCallback onTap;

  const ConsumerThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
  });

  ({OfferStatus status, String? labelOverride}) _resolveStatus() {
    if (thread.bestOfferStatus == 'BOUGHT') {
      return (status: OfferStatus.bought, labelOverride: 'COMPRADA');
    }
    if (thread.bestOfferStatus == 'DELIVERED') {
      return (status: OfferStatus.delivered, labelOverride: null);
    }
    if (!thread.isOpen || thread.isExpired) {
      return (status: OfferStatus.discarded, labelOverride: 'CERRADA');
    }
    final hasOffers = thread.totalOffersCount > 0 || thread.bestOfferPrice != null;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  String _offersLabel() {
    final n = thread.totalOffersCount;
    if (n == 0) return 'Sin cotizaciones';
    return '$n cotización${n > 1 ? 'es' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final expStr = expirationLabel(thread.expiresAt, isExpired: thread.isExpired);
    final resolved = _resolveStatus();
    final status = resolved.status;
    final isClosed = status == OfferStatus.discarded;
    final hasBestOffer = thread.bestOfferPrice != null;

    final semanticLabel = StringBuffer('Solicitud ${thread.title}');
    if (thread.subcategory != null) semanticLabel.write(', ${thread.subcategory}');
    semanticLabel.write(', ${(resolved.labelOverride ?? status.label).toLowerCase()}');
    if (hasBestOffer) {
      semanticLabel.write(', mejor oferta ${thread.bestOfferPrice!.toStringAsFixed(0)} lempiras');
    }
    if (!isClosed && expStr.isNotEmpty) semanticLabel.write(', $expStr');

    return CardShell(
      onTap: onTap,
      semanticLabel: semanticLabel.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Zona 1: estado + expiración ──────────────────────────────────
          Row(
            children: [
              Flexible(
                child: StatusBadge(status: status, labelOverride: resolved.labelOverride),
              ),
              const Spacer(),
              if (!isClosed && expStr.isNotEmpty) ...[
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMeta),
                const SizedBox(width: 4),
                Text(expStr, style: CardTokens.meta),
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

          // ── Zona 3: footer con la mejor oferta ───────────────────────────
          const CardDivider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasBestOffer ? 'MEJOR OFERTA' : 'ESTADO',
                      style: CardTokens.overline,
                    ),
                    const SizedBox(height: 2),
                    if (hasBestOffer)
                      PriceText(
                        amount: thread.bestOfferPrice,
                        style: CardTokens.price.copyWith(color: AppColors.primary),
                      )
                    else
                      Text(
                        'Esperando ofertas',
                        style: CardTokens.metaStrong,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: MetaLine(
                  items: [
                    if (hasBestOffer && thread.bestOfferStoreName != null)
                      MetaItem(thread.bestOfferStoreName!, color: AppColors.celesteInk),
                    MetaItem(_offersLabel(), color: AppColors.celesteInk),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 20),
            ],
          ),
        ],
      ),
    );
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
}
