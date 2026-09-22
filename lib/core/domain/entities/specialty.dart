import 'package:equatable/equatable.dart';

/// Automotive specialty shared by catalog and provider profile.
class Specialty extends Equatable {
  final String id;
  final String name;

  const Specialty({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
