import 'package:flutter/material.dart';

/// Tipo de repuesto disponible para búsqueda.
/// Mapea directamente al enum `PartType` del backend.
enum PartType {
  performance,
  original,
  generic,
}

extension PartTypeX on PartType {
  /// Valor que se envía al backend (debe coincidir con el enum de Prisma).
  String get apiValue {
    switch (this) {
      case PartType.performance:
        return 'PERFORMANCE';
      case PartType.original:
        return 'ORIGINAL';
      case PartType.generic:
        return 'GENERIC';
    }
  }

  /// Etiqueta para mostrar en el UI.
  String get label {
    switch (this) {
      case PartType.performance:
        return 'Alto rendimiento';
      case PartType.original:
        return 'OEM';
      case PartType.generic:
        return 'Genérico';
    }
  }

  /// Descripción corta para el UI.
  String get description {
    switch (this) {
      case PartType.performance:
        return 'Mejora el desempeño';
      case PartType.original:
        return 'Equipo del fabricante';
      case PartType.generic:
        return 'Alternativo / compatible';
    }
  }

  /// Icono representativo del tipo.
  IconData get icon {
    switch (this) {
      case PartType.performance:
        return Icons.speed_rounded;
      case PartType.original:
        return Icons.verified_rounded;
      case PartType.generic:
        return Icons.handyman_rounded;
    }
  }
}
