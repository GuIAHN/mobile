import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/domain/enums/offer_status.dart';
import '../../../../shared/utils/subcategory_presentation.dart';
import '../../domain/entities/chat_thread.dart';
import '_atoms/card_shell.dart';
import '_atoms/card_tokens.dart';
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
    final hasOffers = _quotesCount > 0;
    if (hasOffers) {
      return (status: OfferStatus.offersReceived, labelOverride: null);
    }
    return (status: OfferStatus.noOffers, labelOverride: null);
  }

  String _offersLabel() {
    final count = _quotesCount;
    if (count == 0) return '0 cotizaciones';
    return '$count ${count == 1 ? 'cotización' : 'cotizaciones'}';
  }

  String _questionsLabel() {
    final count = _questionsCount;
    return '$count ${count == 1 ? 'pregunta' : 'preguntas'}';
  }

  int get _quotesCount => thread.quotesCount < 0 ? 0 : thread.quotesCount;

  int get _questionsCount =>
      thread.questionsCount < 0 ? 0 : thread.questionsCount;

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
    final requestMetaLabel = _requestMetaLabel();
    final subcategoryLabel = _subcategoryLabel;

    final semanticLabel = StringBuffer('Solicitud ${thread.title}');
    if (thread.subcategory != null) {
      semanticLabel.write(', $subcategoryLabel');
    }
    semanticLabel.write(
      ', ${(resolved.labelOverride ?? status.label).toLowerCase()}',
    );
    semanticLabel.write(', ${_offersLabel()}, ${_questionsLabel()}');
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CardThumb(
                      key: const Key('consumer-request-thumbnail'),
                      url: thread.fotoUrl,
                      vehicleType: thread.vehicleType,
                      title: thread.title,
                      size: 112,
                      enableViewer: false,
                    ),
                    if (isTerminal)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _TerminalStatusBadge(status: status),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    key: const Key('consumer-request-text-content'),
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isTerminal) ...[
                        _RequestHeader(
                          status: status,
                          expiration: expiration,
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        thread.title,
                        maxLines: 1,
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
                        offersLabel: _offersLabel(),
                        questionsLabel: _questionsLabel(),
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
        _subcategoryLabel,
      if (thread.partType != null && thread.partType!.trim().isNotEmpty)
        _partTypeLabel(thread.partType!),
    ].join(' · ');
  }

  String get _subcategoryLabel => presentSubcategoryPath(
        categoryName: thread.categoryName,
        subcategoryName: thread.subcategory,
        isCatchAll: thread.subcategoryIsCatchAll,
        audience: SubcategoryPresentationAudience.requester,
      );

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
}

class _TerminalStatusBadge extends StatelessWidget {
  final OfferStatus status;

  const _TerminalStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('consumer-request-terminal-status'),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppLineIcon(
        _statusIcon(status),
        size: AppIconSize.inline,
        color: status.foreground,
      ),
    );
  }
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

/// Contador discreto integrado al contenido principal. No crea un footer ni
/// repite el estado de la solicitud.
class _OfferMeta extends StatelessWidget {
  final String offersLabel;
  final String questionsLabel;

  const _OfferMeta({
    required this.offersLabel,
    required this.questionsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final offersStyle = CardTokens.metaStrong.copyWith(
      color: AppColors.celesteInk,
      fontSize: 12,
    );
    final questionsStyle = CardTokens.metaStrong.copyWith(
      color: AppColors.textMeta,
      fontSize: 12,
    );
    return Column(
      key: const Key('consumer-request-offers-meta'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricLabel(
          icon: AppIcons.offer,
          iconKey: const Key('consumer-request-quotes-icon'),
          label: offersLabel,
          style: offersStyle,
          allowWrap: true,
        ),
        const SizedBox(height: 6),
        _MetricLabel(
          icon: AppIcons.question,
          iconKey: const Key('consumer-request-questions-icon'),
          label: questionsLabel,
          style: questionsStyle,
          allowWrap: true,
        ),
      ],
    );
  }
}

class _MetricLabel extends StatelessWidget {
  final IconData icon;
  final Key iconKey;
  final String label;
  final TextStyle style;
  final bool allowWrap;

  const _MetricLabel({
    required this.icon,
    required this.iconKey,
    required this.label,
    required this.style,
    this.allowWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppLineIcon(
          icon,
          key: iconKey,
          size: AppIconSize.inline,
          color: style.color,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: allowWrap ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
