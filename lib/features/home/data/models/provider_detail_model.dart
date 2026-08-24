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
    super.ratingCount,
    super.tarifa,
    super.distanciaKm,
    super.especialidades,
    super.verified,
    super.identificacion,
    super.telefono,
    super.email,
    super.direccion,
    super.lat,
    super.lng,
    super.hasDelivery,
    super.categorias,
    super.photo,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static String? _parseIdentification(dynamic identData) {
    if (identData is Map) {
      final prefix = identData['prefix']?.toString();
      final number = identData['number']?.toString();
      if (prefix != null && number != null) {
        return '$prefix-$number';
      }
    }
    return null;
  }

  factory ProviderDetailModel.fromMechanicJson(Map<String, dynamic> json) {
    final especialidades = (json['specialties'] as List<dynamic>? ?? [])
        .map((s) => s is Map ? s['name'].toString() : s.toString())
        .toList();

    final locationMap = json['location'] as Map<String, dynamic>?;
    final lat = _toDouble(locationMap?['lat'] ?? json['latitude']);
    final lng = _toDouble(
        locationMap?['lon'] ?? locationMap?['lng'] ?? json['longitude']);
    final ratingCount = _toInt(json['ratingCount'] ?? json['rating_count']);
    final ident = _parseIdentification(json['identification']);
    final photo =
        json['photo'] as String? ?? (json['user'] as Map?)?['photo'] as String?;

    return ProviderDetailModel(
      id: json['id'] as String,
      userId:
          json['userId'] as String? ?? (json['user'] as Map?)?['id'] as String?,
      nombre: json['name'] as String? ??
          json['nombre'] as String? ??
          (json['user'] as Map?)?['name'] as String? ??
          'Sin nombre',
      esTaller:
          json['isWorkshop'] as bool? ?? json['esTaller'] as bool? ?? false,
      descripcion:
          json['description'] as String? ?? json['descripcion'] as String?,
      rating: _toDouble(json['rating']),
      ratingCount: ratingCount,
      tarifa: _toDouble(json['rate'] ?? json['tarifa']),
      especialidades: especialidades,
      verified: json['verified'] as bool? ?? false,
      identificacion: ident,
      telefono: json['phone'] as String? ?? json['telefono'] as String?,
      email: json['email'] as String?,
      direccion: json['address'] as String? ?? json['direccion'] as String?,
      lat: lat,
      lng: lng,
      photo: photo,
    );
  }

  factory ProviderDetailModel.fromStoreJson(Map<String, dynamic> json) {
    final nombre = json['nombre'] as String? ??
        json['name'] as String? ??
        (json['user'] as Map?)?['name'] as String? ??
        'Sin nombre';

    final coverage = json['coverage'] as Map<String, dynamic>?;
    final coverageBrands = coverage?['brands'] as List<dynamic>? ?? const [];
    final categorias = (coverage?['subcategories'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((c) => ProviderCategory(
              name: c['name']?.toString() ?? 'Subcategoría',
              brands: coverageBrands
                  .map((b) => b is Map ? b['name'].toString() : b.toString())
                  .toList(),
            ))
        .toList();

    final locationMap = json['location'] as Map<String, dynamic>?;
    final lat = _toDouble(locationMap?['lat'] ?? json['latitude']);
    final lng = _toDouble(
        locationMap?['lon'] ?? locationMap?['lng'] ?? json['longitude']);
    final ratingCount = _toInt(json['ratingCount'] ?? json['rating_count']);
    final ident = _parseIdentification(json['identification']);
    final photo =
        json['photo'] as String? ?? (json['user'] as Map?)?['photo'] as String?;

    return ProviderDetailModel(
      id: json['id'] as String,
      userId:
          json['userId'] as String? ?? (json['user'] as Map?)?['id'] as String?,
      nombre: nombre,
      esTaller: true,
      descripcion:
          json['description'] as String? ?? json['descripcion'] as String?,
      rating: _toDouble(json['rating']),
      ratingCount: ratingCount,
      identificacion: ident,
      email: json['email'] as String?,
      telefono: json['phone'] as String? ?? json['telefono'] as String?,
      direccion: json['address'] as String? ?? json['direccion'] as String?,
      lat: lat,
      lng: lng,
      hasDelivery: json['hasDelivery'] as bool? ?? false,
      categorias: categorias,
      photo: photo,
    );
  }
}
