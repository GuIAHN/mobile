import '../../domain/entities/provider_detail.dart';

/// Modelo para el perfil público completo devuelto por:
/// - [GET /mechanics/:id]
/// - [GET /stores/:id]
///
/// Ambos endpoints retornan campos similares; los específicos de stores
/// (e.g. categorías) se ignorarán hasta que se agreguen al dominio.
class ProviderDetailModel extends ProviderDetail {
  const ProviderDetailModel({
    required super.id,
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
  });

  factory ProviderDetailModel.fromMechanicJson(Map<String, dynamic> json) {
    final especialidades =
        (json['specialties'] as List<dynamic>? ?? [])
            .map((s) => s is Map ? s['name'].toString() : s.toString())
            .toList();

    return ProviderDetailModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String? ??
          (json['user'] as Map?)?['name'] as String? ??
          'Sin nombre',
      esTaller: json['esTaller'] as bool? ?? false,
      descripcion: json['descripcion'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      tarifa: (json['tarifa'] as num?)?.toDouble(),
      especialidades: especialidades,
      verified: json['verified'] as bool? ?? false,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
    );
  }

  factory ProviderDetailModel.fromStoreJson(Map<String, dynamic> json) {
    // El perfil público de stores tiene estructura diferente a mechanics
    final nombre = json['nombre'] as String? ??
        (json['user'] as Map?)?['name'] as String? ??
        'Sin nombre';

    return ProviderDetailModel(
      id: json['id'] as String,
      nombre: nombre,
      esTaller: true,
      descripcion: json['descripcion'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      email: json['email'] as String?,
      telefono: json['telefono'] as String?,
    );
  }
}
