import 'package:equatable/equatable.dart';
import '../../../../core/domain/enums/user_role.dart';

/// Entidad de usuario autenticado (dominio puro, sin JSON ni Flutter).
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final UserRole role;
  final bool approved;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.role = UserRole.unknown,
    this.approved = true,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, phone, role, approved];
}
