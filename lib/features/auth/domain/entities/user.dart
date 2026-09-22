import 'package:equatable/equatable.dart';
import '../../../../core/domain/enums/account_status.dart';
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
  final AccountStatus accountStatus;
  final DateTime? deletionRequestedAt;
  final DateTime? deletionScheduledAt;
  final String? authProvider;

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
    this.accountStatus = AccountStatus.active,
    this.deletionRequestedAt,
    this.deletionScheduledAt,
    this.authProvider,
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
        accountStatus,
        deletionRequestedAt,
        deletionScheduledAt,
        authProvider,
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
    AccountStatus? accountStatus,
    DateTime? deletionRequestedAt,
    DateTime? deletionScheduledAt,
    String? authProvider,
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
      accountStatus: accountStatus ?? this.accountStatus,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      deletionScheduledAt: deletionScheduledAt ?? this.deletionScheduledAt,
      authProvider: authProvider ?? this.authProvider,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cars: cars ?? this.cars,
    );
  }

  bool get isPendingDeletion => accountStatus == AccountStatus.pendingDeletion;

  bool get requiresDeletionPassword =>
      authProvider == null || authProvider!.trim().isEmpty;
}
