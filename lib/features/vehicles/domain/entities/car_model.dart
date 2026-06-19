import 'package:equatable/equatable.dart';

/// Pure domain entity representing a specific vehicle model.
class CarModel extends Equatable {
  final String id;
  final String brandId;
  final String name;
  final String motor;
  final int year;

  const CarModel({
    required this.id,
    required this.brandId,
    required this.name,
    required this.motor,
    required this.year,
  });

  @override
  List<Object?> get props => [id, brandId, name, motor, year];
}
