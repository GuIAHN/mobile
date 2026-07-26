import 'package:flutter/material.dart';
import '../../../../../core/domain/enums/offer_status.dart';
import 'card_tokens.dart';

/// Badge de estado — el **único relleno de énfasis** permitido en una card.
///
/// Al ser el único elemento con fondo de color, se convierte en el ancla de
/// escaneo de la lista: el ojo lo encuentra primero y de ahí baja al título y
/// al precio. Cuando cada card tenía 5-6 rellenos compitiendo, este badge se
/// perdía entre ellos.
///
/// Siempre lleva ícono: el estado nunca se transmite solo por color
/// (WCAG `color-not-only`).
class StatusBadge extends StatelessWidget {
  final OfferStatus status;

  /// Etiqueta alternativa (ej. "COMPRADA" en vez de "¡VENDIDA!" según la
  /// perspectiva de quien mira la card).
  final String? labelOverride;

  const StatusBadge({
    super.key,
    required this.status,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final label = labelOverride ?? status.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CardTokens.status.copyWith(color: status.foreground),
            ),
          ),
        ],
      ),
    );
  }
}
