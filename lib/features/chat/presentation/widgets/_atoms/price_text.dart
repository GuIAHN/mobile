import 'package:flutter/material.dart';
import '../../../../../core/utils/formatters.dart';
import 'card_tokens.dart';

/// Texto de precio único para las cards.
///
/// Antes el precio se formateaba de 3 formas distintas entre cards
/// (`Formatters.currency`, `formattedPrice` sin separadores, `toStringAsFixed`
/// crudo) y solo una card usaba cifras tabulares, así que las columnas de
/// precio bailaban justo en la pantalla donde el usuario compara ofertas.
///
/// Siempre usa [Formatters.currency] + cifras tabulares (vía [CardTokens]).
class PriceText extends StatelessWidget {
  final double? amount;
  final double? minAmount;
  final double? maxAmount;

  /// Estilo del precio. Por defecto [CardTokens.price]; usar
  /// [CardTokens.priceHero] cuando el precio es el elemento dominante.
  final TextStyle? style;

  /// Texto cuando no hay precio (ej. "Sin cotizar", "A convenir").
  final String fallback;

  const PriceText({
    super.key,
    this.amount,
    this.minAmount,
    this.maxAmount,
    this.style,
    this.fallback = 'Sin cotizar',
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    if (amount != null) {
      text = Formatters.currency(amount!);
    } else if (minAmount != null && maxAmount != null) {
      text = '${Formatters.currency(minAmount!)} - ${Formatters.currency(maxAmount!)}';
    } else {
      text = fallback;
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style ?? CardTokens.price,
    );
  }
}
