import 'package:equatable/equatable.dart';

/// Pure domain entity representing a vehicle brand.
class Brand extends Equatable {
  final String id;
  final String name;
  final String brandType;
  final String? photoUrl;

  const Brand({
    required this.id,
    required this.name,
    required this.brandType,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, name, brandType, photoUrl];
}
