import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Estado de una oferta/cotización o de una solicitud de búsqueda sin oferta.
/// Mapea al enum `OfferStatus` de Prisma en el backend (`SENT`, `ACCEPTED`,
/// `DISCARDED`, `BOUGHT`, `DELIVERED`), más estados que solo existen en el
/// cliente (`noOffers`, `offersReceived`, `unquoted`, `noQuoteYet`) para las
/// cards que muestran una solicitud o chat antes de que exista una oferta.
enum OfferStatus {
  /// Solicitud sin ninguna oferta todavía (vista consumidor).
  noOffers,

  /// Solicitud con ofertas recibidas, pendiente de revisión (vista consumidor).
  offersReceived,

  /// Solicitud sin cotizar por esta tienda (vista tienda) — acción pendiente.
  unquoted,

  /// Chat sin cotización formal adjunta (vista tienda, "Mis Chats"). A
  /// diferencia de [unquoted], no implica una acción pendiente: es una
  /// conversación directa que nunca tuvo o ya no tiene una oferta asociada.
  noQuoteYet,

  /// Cotización enviada, pendiente de decisión del consumidor.
  sent,

  /// Cotización aceptada por el consumidor pero todavía no comprada.
  accepted,

  /// Oferta descartada (el consumidor eligió otra).
  discarded,

  /// Oferta comprada, pendiente de entrega.
  bought,

  /// Oferta entregada — ciclo cerrado.
  delivered,
}

extension OfferStatusX on OfferStatus {
  /// Parsea el string crudo del backend (`offerStatus`/`bestOfferStatus`).
  /// [hasOffer] distingue entre "sin ofertas" (solicitud) y "sin cotizar"
  /// (tienda) cuando el status es null.
  static OfferStatus fromApi(String? status, {bool hasOffer = false}) {
    switch (status) {
      case 'SENT':
        return OfferStatus.sent;
      case 'ACCEPTED':
        return OfferStatus.accepted;
      case 'DISCARDED':
        return OfferStatus.discarded;
      case 'BOUGHT':
        return OfferStatus.bought;
      case 'DELIVERED':
        return OfferStatus.delivered;
      default:
        return hasOffer ? OfferStatus.sent : OfferStatus.unquoted;
    }
  }

  String get label {
    switch (this) {
      case OfferStatus.noOffers:
        return 'BUSCANDO';
      case OfferStatus.offersReceived:
        return 'OFERTAS RECIBIDAS';
      case OfferStatus.unquoted:
        return 'NUEVA SOLICITUD';
      case OfferStatus.noQuoteYet:
        return 'CHAT EN PROGRESO';
      case OfferStatus.sent:
      case OfferStatus.accepted:
        return 'COTIZADA';
      case OfferStatus.discarded:
        return 'DESCARTADA';
      case OfferStatus.bought:
        return '¡VENDIDA!';
      case OfferStatus.delivered:
        return 'ENTREGADA';
    }
  }

  /// Etiqueta desde la perspectiva del consumidor (vista "mis solicitudes").
  String get consumerLabel {
    switch (this) {
      case OfferStatus.bought:
        return 'COMPRADA';
      default:
        return label;
    }
  }

  IconData get icon {
    switch (this) {
      case OfferStatus.noOffers:
        return Icons.hourglass_empty_rounded;
      case OfferStatus.offersReceived:
        return Icons.local_offer_rounded;
      case OfferStatus.unquoted:
        return Icons.bolt_rounded;
      case OfferStatus.noQuoteYet:
        return Icons.chat_bubble_outline_rounded;
      case OfferStatus.sent:
      case OfferStatus.accepted:
        return Icons.send_rounded;
      case OfferStatus.discarded:
        return Icons.cancel_rounded;
      case OfferStatus.bought:
        return Icons.shopping_bag_rounded;
      case OfferStatus.delivered:
        return Icons.check_circle_rounded;
    }
  }

  Color get background {
    switch (this) {
      case OfferStatus.noOffers:
        return AppColors.warningLight;
      case OfferStatus.offersReceived:
        return AppColors.primaryMuted;
      case OfferStatus.unquoted:
        return AppColors.primaryMuted;
      case OfferStatus.noQuoteYet:
        return AppColors.grey100;
      case OfferStatus.sent:
      case OfferStatus.accepted:
        return AppColors.celesteMuted;
      case OfferStatus.bought:
        return AppColors.successLight;
      case OfferStatus.delivered:
      case OfferStatus.discarded:
        return AppColors.grey100;
    }
  }

  Color get foreground {
    switch (this) {
      case OfferStatus.noOffers:
        return AppColors.warningInk;
      case OfferStatus.offersReceived:
        return AppColors.primaryInk;
      case OfferStatus.unquoted:
        return AppColors.primaryInk;
      case OfferStatus.noQuoteYet:
        return AppColors.grey700;
      case OfferStatus.sent:
      case OfferStatus.accepted:
        return AppColors.celesteInk;
      case OfferStatus.bought:
        return AppColors.successInk;
      case OfferStatus.delivered:
      case OfferStatus.discarded:
        // grey700 sobre grey100 = 7.35:1 — AppColors.textDisabled (2.07:1)
        // fallaría WCAG AA aquí.
        return AppColors.grey700;
    }
  }
}
