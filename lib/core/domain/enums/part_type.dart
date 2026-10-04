import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';

/// Tipo de repuesto disponible para búsqueda.
/// Mapea directamente al enum `PartType` del backend.
enum PartType {
  performance,
  original,
  generic,
  used,
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
      case PartType.used:
        return 'USED';
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
      case PartType.used:
        return 'Usado';
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
      case PartType.used:
        return 'Repuesto previamente utilizado';
    }
  }

  /// Icono representativo del tipo.
  IconData get icon {
    switch (this) {
      case PartType.performance:
        return AppIcons.partPerformance;
      case PartType.original:
        return AppIcons.partOriginal;
      case PartType.generic:
        return AppIcons.partGeneric;
      case PartType.used:
        return AppIcons.partUsed;
    }
  }
}

String partTypeLabelFromApi(String raw) {
  for (final type in PartType.values) {
    if (type.apiValue == raw) return type.label;
  }
  return raw;
}
