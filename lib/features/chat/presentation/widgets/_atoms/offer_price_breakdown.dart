import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';

/// Resumen monetario que mantiene separados producto, delivery y total.
///
/// Si no existe delivery, evita repetir el mismo importe como subtotal y
/// total. Cuando el backend provee [totalCost], ese valor conserva prioridad.
class OfferPriceBreakdown extends StatelessWidget {
  const OfferPriceBreakdown({
    super.key,
    required this.productCost,
    this.deliveryCost,
    this.totalCost,
    this.width = 152,
  });

  final double? productCost;
  final double? deliveryCost;
  final double? totalCost;
  final double width;

  double? get _resolvedTotal {
    if (totalCost != null) return totalCost;
    if (productCost == null) return null;
    return productCost! + (deliveryCost ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth =
        MediaQuery.textScalerOf(context).scale(1) > 1.25 ? 220.0 : width;

    if (productCost == null) {
      return Text(
        'A convenir',
        key: const Key('offer-price-open'),
        style: _amountStyle,
      );
    }

    if (deliveryCost == null) {
      return SizedBox(
        width: effectiveWidth,
        child: _PriceLine(
          label: 'Producto',
          value: Formatters.currency(productCost!),
          valueKey: const Key('offer-product-cost'),
          emphasized: true,
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PriceLine(
            label: 'Producto',
            value: Formatters.currency(productCost!),
            valueKey: const Key('offer-product-cost'),
          ),
          const SizedBox(height: 3),
          _PriceLine(
            label: 'Delivery',
            value: deliveryCost == 0
                ? 'Gratis'
                : Formatters.currency(deliveryCost!),
            valueKey: const Key('offer-delivery-cost'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _PriceLine(
            label: 'Total',
            value: Formatters.currency(_resolvedTotal!),
            valueKey: const Key('offer-total-cost'),
            emphasized: true,
          ),
        ],
      ),
    );
  }

  TextStyle get _amountStyle => GoogleFonts.hankenGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
      );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    required this.valueKey,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: emphasized ? 11.5 : 10.5,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color:
                  emphasized ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          key: valueKey,
          style: GoogleFonts.hankenGrotesk(
            fontSize: emphasized ? 16 : 11.5,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            color: emphasized ? AppColors.primary : AppColors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
