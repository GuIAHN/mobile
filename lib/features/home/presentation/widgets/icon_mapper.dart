import 'package:flutter/material.dart';

/// Convierte el nombre de un icono de dominio en un [IconData] de Material.
IconData getIconData(String name) {
  switch (name) {
    case 'verified_outlined':
      return Icons.verified_outlined;
    case 'home_repair_service_outlined':
      return Icons.home_repair_service_outlined;
    case 'local_offer_outlined':
      return Icons.local_offer_outlined;
    case 'bolt_outlined':
      return Icons.bolt_outlined;
    case 'oil_barrel_outlined':
      return Icons.oil_barrel_outlined;
    case 'handyman_outlined':
      return Icons.handyman_outlined;
    case 'format_paint_outlined':
      return Icons.format_paint_outlined;
    case 'build_outlined':
      return Icons.build_outlined;
    case 'settings_outlined':
      return Icons.settings_outlined;
    case 'warehouse_outlined':
      return Icons.warehouse_outlined;
    default:
      return Icons.help_outline;
  }
}
