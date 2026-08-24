import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
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
    final hasOffers =
        thread.totalOffersCount > 0 || thread.bestOfferPrice != null;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  String _offersLabel() {
    final count = thread.totalOffersCount;
    if (count == 0) return '0 cotizaciones';
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
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
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
                  labelOverride: resolved.labelOverride,
                  expiration: !isTerminal ? expiration : '',
                ),
                const SizedBox(height: 8),
                Text(
                  thread.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CardTokens.title.copyWith(fontSize: 16),
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
                  const SizedBox(height: CardTokens.tight),
                  Text(
                    thread.details!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CardTokens.body,
                  ),
                ],
                const SizedBox(height: 12),
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledBody = MediaQuery.textScalerOf(context).scale(14);
        final shouldWrap = constraints.maxWidth < 180 || scaledBody > 19;

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
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: statusBadge,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: expirationMeta),
          ],
        );
      },
    );
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
        const SizedBox(width: 8),
        const AppLineIcon(
          AppIcons.next,
          size: AppIconSize.action,
          color: AppColors.grey600,
        ),
      ],
    );
  }
}
