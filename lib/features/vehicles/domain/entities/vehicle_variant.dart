import 'package:equatable/equatable.dart';

/// Pure domain entity representing a vehicle variant (year & engine configuration).
class VehicleVariant extends Equatable {
  final String id;
  final String modelId;
  final int year;
  final String motor;

  const VehicleVariant({
    required this.id,
    required this.modelId,
    required this.year,
    required this.motor,
  });

  @override
  List<Object?> get props => [id, modelId, year, motor];
}
