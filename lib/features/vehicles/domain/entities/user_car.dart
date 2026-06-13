import 'package:equatable/equatable.dart';

/// Entidad pura de vehículo de usuario (UserCar) para la capa de dominio.
class UserCar extends Equatable {
  final String id;
  final String brand;
  final String model;
  final int year;

  const UserCar({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  @override
  List<Object?> get props => [id, brand, model, year];
}
