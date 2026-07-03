import 'package:equatable/equatable.dart';

/// Entidad de detalle completo de un proveedor (mecánico o taller).
/// Usada en las pantallas de detalle (Tarea 5 y 6).
class ProviderDetail extends Equatable {
  final String id;
  final String nombre;
  final bool esTaller;
  final String? descripcion;
  final double? rating;
  final double? tarifa;
  final double? distanciaKm;
  final List<String> especialidades;
  final bool verified;
  final String? telefono;
  final String? email;

  const ProviderDetail({
    required this.id,
    required this.nombre,
    required this.esTaller,
    this.descripcion,
    this.rating,
    this.tarifa,
    this.distanciaKm,
    this.especialidades = const [],
    this.verified = false,
    this.telefono,
    this.email,
  });

  String get displayType => esTaller ? 'Taller Mecánico' : 'Mecánico';

  @override
  List<Object?> get props => [
        id,
        nombre,
        esTaller,
        descripcion,
        rating,
        tarifa,
        distanciaKm,
        especialidades,
        verified,
        telefono,
        email,
      ];
}
