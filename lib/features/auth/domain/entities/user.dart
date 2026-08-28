import 'package:equatable/equatable.dart';
import '../../../../core/domain/enums/user_role.dart';
import '../../../../core/domain/entities/user_car.dart';

/// Entidad de usuario autenticado (dominio puro, sin JSON ni Flutter).
class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String? phone;
  final String? description;
  final UserRole role;
  final bool approved;

  // Ubicación y garage cacheados al login
  final double? latitude;
  final double? longitude;
  final List<UserCar>? cars;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.phone,
    this.description,
    this.role = UserRole.unknown,
    this.approved = true,
    this.latitude,
    this.longitude,
    this.cars,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        phone,
        description,
        role,
        approved,
        latitude,
        longitude,
        cars,
      ];

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? phone,
    String? description,
    UserRole? role,
    bool? approved,
    double? latitude,
    double? longitude,
    List<UserCar>? cars,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cars: cars ?? this.cars,
    );
  }
}
