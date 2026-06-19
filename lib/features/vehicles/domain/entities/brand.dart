import 'package:equatable/equatable.dart';

/// Pure domain entity representing a vehicle brand.
class Brand extends Equatable {
  final String id;
  final String name;
  final String brandType;

  const Brand({
    required this.id,
    required this.name,
    required this.brandType,
  });

  @override
  List<Object?> get props => [id, name, brandType];
}
