import 'package:equatable/equatable.dart';

/// Categoría de repuestos que ofrece una tienda, con precio base opcional.
class ProviderCategory extends Equatable {
  final String name;
  final double? startingPrice;
  final List<String> brands;

  const ProviderCategory({
    required this.name,
    this.startingPrice,
    this.brands = const [],
  });

  @override
  List<Object?> get props => [name, startingPrice, brands];
}

/// Entidad de detalle completo de un proveedor (mecánico o taller).
/// Usada en las pantallas de detalle (Tarea 5 y 6).
class ProviderDetail extends Equatable {
  final String id;

  /// ID del usuario dueño del perfil — necesario para iniciar un chat directo.
  final String? userId;
  final String nombre;
  final bool esTaller;
  final String? descripcion;
  final double? rating;
  final int ratingCount;
  final double? tarifa;
  final double? distanciaKm;
  final List<String> especialidades;
  final bool verified;
  final String? identificacion;
  final String? telefono;
  final String? email;
  final String? direccion;
  final double? lat;
  final double? lng;
  final bool hasDelivery;
  final List<ProviderCategory> categorias;
  final String? photo;

  const ProviderDetail({
    required this.id,
    this.userId,
    required this.nombre,
    required this.esTaller,
    this.descripcion,
    this.rating,
    this.ratingCount = 0,
    this.tarifa,
    this.distanciaKm,
    this.especialidades = const [],
    this.verified = false,
    this.identificacion,
    this.telefono,
    this.email,
    this.direccion,
    this.lat,
    this.lng,
    this.hasDelivery = false,
    this.categorias = const [],
    this.photo,
  });

  String get displayType => esTaller ? 'Taller Mecánico' : 'Mecánico';

  @override
  List<Object?> get props => [
        id,
        userId,
        nombre,
        esTaller,
        descripcion,
        rating,
        ratingCount,
        tarifa,
        distanciaKm,
        especialidades,
        verified,
        identificacion,
        telefono,
        email,
        direccion,
        lat,
        lng,
        hasDelivery,
        categorias,
        photo,
      ];
}
