import '../../domain/entities/provider_detail.dart';

/// Modelo para el perfil público completo devuelto por:
/// - [GET /mechanics/:id]
/// - [GET /stores/:id]
///
/// El backend responde con claves en inglés (`description`, `rate`, `phone`,
/// `isWorkshop`...); se mantienen las claves en español como fallback por
/// compatibilidad con versiones anteriores de la API.
class ProviderDetailModel extends ProviderDetail {
  const ProviderDetailModel({
    required super.id,
    super.userId,
    required super.nombre,
    required super.esTaller,
    super.descripcion,
    super.rating,
    super.tarifa,
    super.distanciaKm,
    super.especialidades,
    super.verified,
    super.telefono,
    super.email,
    super.direccion,
    super.hasDelivery,
    super.categorias,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  factory ProviderDetailModel.fromMechanicJson(Map<String, dynamic> json) {
    final especialidades = (json['specialties'] as List<dynamic>? ?? [])
        .map((s) => s is Map ? s['name'].toString() : s.toString())
        .toList();

    return ProviderDetailModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ??
          (json['user'] as Map?)?['id'] as String?,
      nombre: json['name'] as String? ??
          json['nombre'] as String? ??
          (json['user'] as Map?)?['name'] as String? ??
          'Sin nombre',
      esTaller: json['isWorkshop'] as bool? ?? json['esTaller'] as bool? ?? false,
      descripcion:
          json['description'] as String? ?? json['descripcion'] as String?,
      rating: _toDouble(json['rating']),
      tarifa: _toDouble(json['rate'] ?? json['tarifa']),
      especialidades: especialidades,
      verified: json['verified'] as bool? ?? false,
      telefono: json['phone'] as String? ?? json['telefono'] as String?,
      email: json['email'] as String?,
    );
  }

  factory ProviderDetailModel.fromStoreJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ??
        json['name'] as String? ??
        (json['user'] as Map?)?['name'] as String? ??
        'Sin nombre';

    final categorias = (json['categories'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((c) => ProviderCategory(
              name: c['categoryName']?.toString() ?? 'Categoría',
              startingPrice: _toDouble(c['startingPrice']),
              brands: (c['brands'] as List<dynamic>? ?? [])
                  .map((b) => b is Map ? b['name'].toString() : b.toString())
                  .toList(),
            ))
        .toList();

    return ProviderDetailModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ??
          (json['user'] as Map?)?['id'] as String?,
      nombre: nombre,
      esTaller: true,
      descripcion:
          json['description'] as String? ?? json['descripcion'] as String?,
      rating: _toDouble(json['rating']),
      email: json['email'] as String?,
      telefono: json['phone'] as String? ?? json['telefono'] as String?,
      direccion: json['address'] as String?,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      categorias: categorias,
    );
  }
}
