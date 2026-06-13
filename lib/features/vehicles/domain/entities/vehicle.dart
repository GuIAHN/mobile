import 'package:equatable/equatable.dart';

/// Entidad pura de vehículo para la capa de dominio.
class Vehicle extends Equatable {
  final UUID id;
  final String brand;
  final String model;
  final int year;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  @override
  List<Object?> get props => [id, brand, model, year];
}
