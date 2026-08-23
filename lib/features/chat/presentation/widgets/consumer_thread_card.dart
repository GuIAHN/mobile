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
/// Mantiene la jerarquía compartida por las cards del inbox:
///   1. Header  — estado + expiración adaptable
///   2. Cuerpo  — miniatura + identidad de la solicitud
///   3. Footer  — resumen contextual de cotizaciones
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
    if (thread.bestOfferStatus == 'CANCELLED') {
      return (status: OfferStatus.cancelled, labelOverride: null);
    }
    if (!thread.isOpen || thread.isExpired) {
      return (status: OfferStatus.discarded, labelOverride: 'CERRADA');
    }
    final hasOffers =
        thread.totalOffersCount > 0 || thread.bestOfferPrice != null;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  String _offersLabel() {
    final count = thread.totalOffersCount;
    if (count == 0) return 'Sin cotizaciones';
    return '$count ${count == 1 ? 'cotización' : 'cotizaciones'}';
  }

  @override
  Widget build(BuildContext context) {
    final expiration = expirationLabel(
      thread.expiresAt,
      isExpired: thread.isExpired,
    );
    final resolved = _resolveStatus();
    final status = resolved.status;
    final isTerminal = status == OfferStatus.discarded ||
        status == OfferStatus.bought ||
        status == OfferStatus.delivered ||
        status == OfferStatus.cancelled;
    final hasBestOffer = thread.bestOfferPrice != null;
    final hasResponses = thread.totalOffersCount > 0 || hasBestOffer;

    final semanticLabel = StringBuffer('Solicitud ${thread.title}');
    if (thread.subcategory != null) {
      semanticLabel.write(', ${thread.subcategory}');
    }
    semanticLabel.write(
      ', ${(resolved.labelOverride ?? status.label).toLowerCase()}',
    );
    if (hasBestOffer) {
      semanticLabel.write(
        ', mejor oferta ${thread.bestOfferPrice!.toStringAsFixed(0)} lempiras',
      );
    }
    if (thread.totalOffersCount > 0) {
      semanticLabel.write(', ${_offersLabel()}');
    }
    if (!isTerminal && expiration.isNotEmpty) {
      semanticLabel.write(', $expiration');
    }

    return CardShell(
      onTap: onTap,
      accentColor: status.accentColor,
      semanticLabel: semanticLabel.toString(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header en el flujo normal: nunca tapa el contenido al escalar.
          _RequestHeader(
            status: status,
            labelOverride: resolved.labelOverride,
            expiration: !isTerminal ? expiration : '',
          ),
          const SizedBox(height: CardTokens.blockGap),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardThumb(
                url: thread.fotoUrl,
                vehicleType: thread.vehicleType,
                title: thread.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CardTokens.title,
                    ),
                    const SizedBox(height: CardTokens.tight),
                    MetaLine(
                      items: [
                        if (thread.subcategory != null)
                          MetaItem(thread.subcategory!),
                        if (thread.partType != null)
                          MetaItem(_partTypeLabel(thread.partType!)),
                      ],
                    ),
                    if (thread.details != null &&
                        thread.details!.trim().isNotEmpty) ...[
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

          const CardDivider(),
          _OfferSummary(
            status: status,
            hasBestOffer: hasBestOffer,
            hasResponses: hasResponses,
            bestOfferPrice: thread.bestOfferPrice,
            bestOfferStoreName: thread.bestOfferStoreName,
            offersLabel: _offersLabel(),
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

/// El vencimiento antes estaba superpuesto sobre la card. En el flujo normal
/// puede bajar de línea en pantallas angostas o con texto grande.
class _RequestHeader extends StatelessWidget {
  final OfferStatus status;
  final String? labelOverride;
  final String expiration;

  const _RequestHeader({
    required this.status,
    required this.labelOverride,
    required this.expiration,
  });

  @override
  Widget build(BuildContext context) {
    final statusBadge = StatusBadge(
      status: status,
      labelOverride: labelOverride,
    );

    if (expiration.isEmpty) return statusBadge;

    final expirationMeta = Text.rich(
      TextSpan(
        children: [
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.only(right: 5),
              child: Icon(
                Icons.schedule_rounded,
                size: 15,
                color: AppColors.textMeta,
              ),
            ),
          ),
          TextSpan(text: expiration),
        ],
      ),
      style: CardTokens.meta.copyWith(fontWeight: FontWeight.w600),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final shouldWrap = constraints.maxWidth < 270 || scaledBody > 19;

        if (shouldWrap) {
          return Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [statusBadge, expirationMeta],
          );
        }

        return Row(
          children: [
            Flexible(child: statusBadge),
            const Spacer(),
            expirationMeta,
          ],
        );
      },
    );
  }
}

/// Footer sobrio y contextual: diferencia entre espera, respuestas recibidas
/// y una búsqueda finalizada sin convertir el precio en un bloque dominante.
class _OfferSummary extends StatelessWidget {
  final OfferStatus status;
  final bool hasBestOffer;
  final bool hasResponses;
  final double? bestOfferPrice;
  final String? bestOfferStoreName;
  final String offersLabel;

  const _OfferSummary({
    required this.status,
    required this.hasBestOffer,
    required this.hasResponses,
    required this.bestOfferPrice,
    required this.bestOfferStoreName,
    required this.offersLabel,
  });

  bool get _isTerminal =>
      status == OfferStatus.discarded ||
      status == OfferStatus.bought ||
      status == OfferStatus.delivered ||
      status == OfferStatus.cancelled;

  String get _heading {
    if (status == OfferStatus.bought) return 'OFERTA COMPRADA';
    if (status == OfferStatus.delivered) return 'OFERTA ENTREGADA';
    if (status == OfferStatus.cancelled) return 'COMPRA CANCELADA';
    if (hasBestOffer) return 'MEJOR OFERTA';
    if (_isTerminal) return 'RESULTADO';
    return 'COTIZACIONES';
  }

  String get _mainText {
    if (hasResponses) return offersLabel;
    if (_isTerminal) return 'Sin cotizaciones';
    return 'Esperando respuestas';
  }

  String get _supportingText {
    if (status == OfferStatus.cancelled) {
      return 'La tienda permanece visible en el historial y en el chat';
    }
    if (hasResponses) return 'Abre la solicitud para revisar las respuestas';
    if (_isTerminal) return 'La búsqueda finalizó sin ofertas';
    return 'Te avisaremos cuando una tienda responda';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_heading, style: CardTokens.overline),
              const SizedBox(height: 3),
              if (hasBestOffer)
                PriceText(
                  amount: bestOfferPrice,
                  style: CardTokens.price.copyWith(color: AppColors.primary),
                )
              else
                Text(
                  _mainText,
                  style: CardTokens.metaStrong.copyWith(
                    fontSize: 14,
                    color: _isTerminal
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              const SizedBox(height: 6),
              if (hasBestOffer)
                MetaLine(
                  items: [
                    if (bestOfferStoreName != null &&
                        bestOfferStoreName!.trim().isNotEmpty)
                      MetaItem(
                        bestOfferStoreName!,
                        icon: Icons.storefront_outlined,
                        color: AppColors.celesteInk,
                      ),
                    MetaItem(
                      offersLabel,
                      icon: Icons.local_offer_outlined,
                      color: AppColors.celesteInk,
                    ),
                  ],
                )
              else
                Text(_supportingText, style: CardTokens.meta),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const SizedBox(
          width: 40,
          height: 48,
          child: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey500,
            size: 22,
          ),
        ),
      ],
    );
  }
}
