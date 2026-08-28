import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../domain/entities/chat_thread.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
import '_atoms/price_text.dart';
import '_atoms/expiration_label.dart';

/// Card de solicitud de búsqueda — vista consumidor.
///
/// La miniatura y toda la información viven en una sola fila compacta para
/// aumentar la densidad sin perder jerarquía ni compatibilidad con Dynamic
/// Type. La barra lateral es la única firma visual y comunica el estado.
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
    // `bestOfferPrice` is the defensive signal that at least one formal
    // quote exists. Older API responses counted price-less INQUIRY chats in
    // totalOffersCount, which produced a phantom "1 cotización".
    final hasOffers = _formalOffersCount > 0;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  String _offersLabel() {
    final count = _formalOffersCount;
    if (count == 0) return '0 cotizaciones';
    return '$count ${count == 1 ? 'cotización' : 'cotizaciones'}';
  }

  int get _formalOffersCount =>
      thread.bestOfferPrice == null ? 0 : thread.totalOffersCount;

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
    final requestMetaLabel = _requestMetaLabel();

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
    if (_formalOffersCount > 0) {
      semanticLabel.write(', ${_offersLabel()}');
    }
    if (!isTerminal && expiration.isNotEmpty) {
      semanticLabel.write(', $expiration');
    }

    return CardShell(
      onTap: onTap,
      accentColor: status.accentColor,
      semanticLabel: semanticLabel.toString(),
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      child: Stack(
        key: const Key('consumer-request-content'),
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 36),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardThumb(
                  key: const Key('consumer-request-thumbnail'),
                  url: thread.fotoUrl,
                  vehicleType: thread.vehicleType,
                  title: thread.title,
                  size: 112,
                  enableViewer: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RequestHeader(
                        status: status,
                        expiration: !isTerminal ? expiration : '',
                      ),
                      const SizedBox(height: 6),
                      Text(
                        thread.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CardTokens.title.copyWith(fontSize: 16),
                      ),
                      if (requestMetaLabel.isNotEmpty) ...[
                        const SizedBox(height: CardTokens.tight),
                        Text(
                          requestMetaLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CardTokens.meta,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _OfferMeta(
                        hasBestOffer: hasBestOffer,
                        bestOfferPrice: thread.bestOfferPrice,
                        offersLabel: _offersLabel(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            key: Key('consumer-request-chevron-slot'),
            width: 32,
            child: Center(
              child: AppLineIcon(
                AppIcons.next,
                size: AppIconSize.action,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _requestMetaLabel() {
    return [
      if (thread.subcategory != null && thread.subcategory!.trim().isNotEmpty)
        thread.subcategory!.trim(),
      if (thread.partType != null && thread.partType!.trim().isNotEmpty)
        _partTypeLabel(thread.partType!),
    ].join(' · ');
  }

  String _partTypeLabel(String raw) {
    switch (raw) {
      case 'ORIGINAL':
        return 'OEM';
      case 'GENERIC':
        return 'Genérico';
      case 'PERFORMANCE':
        return 'Alto rendimiento';
      default:
        return raw;
    }
  }
}

/// Encabezado compacto: el estado se comunica con un solo icono y el texto de
/// vencimiento permanece en la misma línea. El nombre accesible completo vive
/// en la semántica de la card.
class _RequestHeader extends StatelessWidget {
  final OfferStatus status;
  final String expiration;

  const _RequestHeader({
    required this.status,
    required this.expiration,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppLineIcon(
          _statusIcon(status),
          key: const Key('consumer-request-status-icon'),
          size: AppIconSize.action,
          color: status.foreground,
        ),
        if (expiration.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.only(right: 5),
                      child: AppLineIcon(
                        AppIcons.time,
                        size: AppIconSize.inline,
                        color: AppColors.textMeta,
                      ),
                    ),
                  ),
                  TextSpan(text: expiration),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CardTokens.meta.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  IconData _statusIcon(OfferStatus status) {
    switch (status) {
      case OfferStatus.noOffers:
        return AppIcons.search;
      case OfferStatus.offersReceived:
        return AppIcons.offer;
      case OfferStatus.unquoted:
        return AppIcons.opportunity;
      case OfferStatus.noQuoteYet:
        return AppIcons.message;
      case OfferStatus.sent:
      case OfferStatus.accepted:
        return AppIcons.send;
      case OfferStatus.discarded:
        return AppIcons.cancellation;
      case OfferStatus.bought:
        return AppIcons.receipt;
      case OfferStatus.delivered:
        return AppIcons.success;
      case OfferStatus.cancelled:
        return AppIcons.cancellation;
      case OfferStatus.unknown:
        return AppIcons.info;
    }
  }
}

/// Contador discreto integrado al contenido principal. No crea un footer ni
/// repite el estado de la solicitud.
class _OfferMeta extends StatelessWidget {
  final bool hasBestOffer;
  final double? bestOfferPrice;
  final String offersLabel;

  const _OfferMeta({
    required this.hasBestOffer,
    required this.bestOfferPrice,
    required this.offersLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('consumer-request-offers-meta'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasBestOffer) ...[
          Flexible(
            child: PriceText(
              amount: bestOfferPrice,
              style: CardTokens.price.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
        ],
        const AppLineIcon(
          AppIcons.offer,
          size: AppIconSize.inline,
          color: AppColors.textMeta,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            offersLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CardTokens.metaStrong.copyWith(
              color: hasBestOffer ? AppColors.celesteInk : AppColors.textMeta,
            ),
          ),
        ),
      ],
    );
  }
}
