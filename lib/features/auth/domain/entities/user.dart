import 'package:equatable/equatable.dart';

/// Entidad de usuario autenticado (dominio puro, sin JSON ni Flutter).
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.role,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, phone, role];
}
