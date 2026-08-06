/// Tipo de servicio disponible en el home.
enum ServiceType {
  storeDashboard,
  spareParts,
  workshops,
  mechanic,
}

extension ServiceTypeX on ServiceType {
  String get label {
    switch (this) {
      case ServiceType.storeDashboard:
        return 'Estadísticas';
      case ServiceType.mechanic:
        return 'Mecánicos';
      case ServiceType.spareParts:
        return 'Repuestos';
      case ServiceType.workshops:
        return 'Talleres';
    }
  }

  String get hint {
    switch (this) {
      case ServiceType.storeDashboard:
        return '';
      case ServiceType.mechanic:
        return 'Buscar mecánico por nombre o especialidad...';
      case ServiceType.spareParts:
        return 'Buscar repuesto, marca o tienda...';
      case ServiceType.workshops:
        return 'Buscar taller por servicio o zona...';
    }
  }
}
