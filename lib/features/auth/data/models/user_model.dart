import '../../domain/entities/user.dart';

/// Modelo de usuario con serialización JSON.
/// Extiende la entidad [User] sin contaminarlo.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatarUrl,
    super.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (phone != null) 'phone': phone,
      };
}

/// Respuesta completa de login que incluye tokens + usuario.
class LoginResponseModel {
  final String accessToken;
  final String? refreshToken;
  final UserModel user;

  const LoginResponseModel({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
