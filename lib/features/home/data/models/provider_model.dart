import '../../domain/entities/home_item.dart';
import '../../../../core/domain/enums/service_type.dart';

/// Modelo de dato para un proveedor (mecánico o taller) devuelto por
/// los endpoints [GET /search/mechanics] y [GET /search/workshops].
///
/// Respuesta del backend:
/// ```json
/// {
///   "id": "uuid",
///   "nombre": "Carlos Rodríguez",
///   "es_taller": false,
///   "descripcion": "Especialista en motor",
///   "tarifa": 150.0,
///   "rating": 4.9,
///   "distancia_km": 0.8,
///   "especialidades": ["Motor", "Inyección"]
/// }
/// ```
class ProviderModel extends HomeItem {
  const ProviderModel({
    required super.id,
    required super.name,
    required super.detail,
    required super.rating,
    required super.reviews,
    required super.distanceKm,
    required super.isOpen,
    required super.iconName,
    required super.type,
    required super.especialidades,
    super.tarifa,
    super.hasDelivery,
  });

  factory ProviderModel.fromJson(
      Map<String, dynamic> json, ServiceType type) {
    final especialidades =
        (json['especialidades'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

    // El detalle muestra las especialidades o una descripción genérica
    final String detail = especialidades.isNotEmpty
        ? especialidades.take(3).join(' · ')
        : (json['descripcion'] as String? ?? '');

    final String iconName =
        type == ServiceType.workshops ? 'warehouse_outlined' : 'build_outlined';

    return ProviderModel(
      id: json['id'] as String,
      name: json['nombre'] as String? ?? 'Sin nombre',
      detail: detail,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: 0, // El endpoint de búsqueda no retorna reviews aún
      distanceKm: (json['distancia_km'] as num?)?.toDouble() ?? 0.0,
      isOpen: true, // El backend filtra activos; asumir disponible
      iconName: iconName,
      type: type,
      especialidades: especialidades,
      tarifa: (json['tarifa'] as num?)?.toDouble(),
      hasDelivery: json['hasDelivery'] as bool? ?? json['has_delivery'] as bool? ?? false,
    );
  }

  /// Convierte la lista de resultados del backend a modelos.
  static List<ProviderModel> fromJsonList(
      List<dynamic> list, ServiceType type) {
    return list
        .map((item) =>
            ProviderModel.fromJson(item as Map<String, dynamic>, type))
        .toList();
  }
}
